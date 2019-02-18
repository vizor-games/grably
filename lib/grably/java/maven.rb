require 'net/http'
require 'rexml/document'
require 'yaml'

module Grably
  # Utitities to work with maven repositories
  module Maven
    # [WIP] Create array of tokens representing maven version.
    # According to :
    #  The Maven coordinate is split in tokens between dots ('.'), hyphens
    #  ('-') and transitions between digits and characters. The separator is
    #  recorded and will have effect on the order. A transition between digits
    #   and characters is equivalent to hypen. Empty tokens are replaced with
    #  "0". This gives a sequence of version numbers (numeric tokens) and
    #  version qualifiers (non-numeric tokens) with "." or "-" prefixes.
    class Version
      def initialize(string)
        @version = string
                   .gsub(/([A-Za-z])([0-9])/, '\1-\2')
                   .gsub(/([0-9])([A-Za-z])/, '\1-\2')
                   .tr('._', '-')
                   .downcase
                   .split('-')
                   .map { |p| p =~ /^\d+$/ ? p.to_i : p }
      end

      def to_a
        @version.dup
      end

      def <=>(o)
        @version
          .zip(o.to_a)
          .map { |x, y| cmp_parts(x, y) }
          .find { |x| x != 0 } || 0
      rescue StandardError => x
        raise "#{@version.to_a.inspect} vs #{o.to_a.inspect}: #{x.message}"
      end

      private

      def cmp_parts(x, y)
        if !x && y
          -1
        elsif x && !y
          1
        elsif x.class == y.class
          x <=> y
        else
          l = x.is_a?(String) ? 0 : 1
          r = y.is_a?(String) ? 0 : 1
          l <=> r
        end
      end
    end
    # Common methods for working with maven repositories and metafiles
    module Commons
      # Read url content as String
      # @param url [String] file url
      # @return [String] file content
      def read(url)
        res = Net::HTTP.get_response(URI.parse(url))
        raise "Error read: #{url}" unless res.is_a?(Net::HTTPSuccess)

        res.body
      end

      # Creates url for file in maven repository using maven coordinates and
      # file location
      # @param repo [String] repository url
      # @param group [String] group id
      # @param artifact [String] artifact id
      # @param rest [String] file location
      # @return [String] file url
      def maven_url(repo, group, artifact, rest)
        "#{repo}/#{group.tr('.', '/')}/#{artifact}/#{rest}"
      end
    end
    # Reads artifact pom and resolves all dependencies for it. Thing is that we
    # need to expand some substitutions but values for them may be in parent
    # projects.
    class ArtifactReader
      include Commons

      attr_reader :repo, :group, :artifact, :version, :classifier

      def initialize(repo, group, artifact, version, classifier = '')
        @repo = repo
        @group = group
        @artifact = artifact
        @version = version
        @classifier = classifier
      end

      # Reads artifact pom and resolves it internal structure. Returns artifact
      # description.
      def read_artifact
        # First read pom file
        pom = read_pom(repo, group, artifact, version)
        puts "@ #{group}:#{artifact}:#{version}"
        parse_pom(pom)
      end

      private

      # Parse pom file to get artifact description. We don't need whole pom but
      # only artifact dependencies. Yet some values may need substitution. So we
      # read pom properties of this pom and parent poms as well.
      def parse_pom(pom)
        # First read dependencies
        dependencies = pom.elements.to_a('/project/dependencies/*').map do |dep|
          parse_dependency(dep)
        end
        # Find all libs we want to exclude from current artifact
        # ref maven(https://maven.apache.org/guides/introduction/introduction-to-optional-and-excludes-dependencies.html):
        #  When you build your project, that artifact will not be added to your
        #  project's classpath by way of the dependency in which the exclusion
        #  was declared.
        exclude = pom.elements.to_a('/project/dependencies/exclusions/*').map do |ex|
          [ex.elements['./groupId'], ex.elements['./artifactId']]
        end
        # Collect all subsitutions. We need to get list of all substitutions and
        # lambdas to apply them.
        subsitutions = collect_substitutions(dependencies)
        # Apply all substitutions
        apply_substitutions(subsitutions, pom) unless subsitutions.empty?

        # Create artifact description
        {
          artifact: essentials.update(files),
          repo: repo,
          dependencies: dependencies,
          exclusions: exclude
        }
      end

      # Create dependency description out of pom dependency node
      def parse_dependency(dep)
        {
          group: dep.elements['./groupId'].text,
          artifact: dep.elements['./artifactId'].text,
          version: safe_get(dep, './version') || '*',
          scope: safe_get(dep, './scope') || 'compile',
          classifier: safe_get(dep, './classifier'),
          optional: safe_get(dep, './optional') == 'true'
        }
      end

      # Scans all dependencies description values and extracts all substitutions
      # as list of pairs [substitution key, lambda]. Lambda is used to inject
      # substitution value into string
      def collect_substitutions(dependencies)
        subst = /\$\{(.+)\}/

        dependencies.flat_map do |dep|
          dep.values
             .select { |v| v.is_a?(String) }
             .select { |v| v =~ subst }
        end
      end

      def apply_substitutions(targets, pom)
        return if targets.empty?

        values = {
          'project.groupId' => group,
          'project.artifactId' => artifact,
          'project.version' => version
        }

        values.update(fetch_props(pom))
        # Collect all substitution values
        targets.each do |target|
          loop do
            match = target.match(/\$\{(.+)\}/) do |m|
              puts "|- #{m[1]} => #{values[m[1]]}"
              target.sub!("${#{m[1]}}", values[m[1]])
            end
            break unless match
          end
        end
        puts '.'
      end

      def fetch_props(pom)
        current = {}
        pom.elements.each('/project/properties/*') do |prop|
          current[prop.name] = prop.text
        end

        parent = pom.elements['/project/parent']
        return current unless parent

        grp = safe_get(parent, './groupId') || raise('Parent group missing')
        art = safe_get(parent, './artifactId') || raise('Parent artifact missing')
        ver = safe_get(parent, './version') || raise('Paren version missing')
        puts "|- Read POM #{grp}:#{art}:#{ver}"
        p = read_pom(repo, grp, art, ver)
        fetch_props(p).merge(current)
      rescue StandardError => x
        id = %w(groupId artifactId version).map do |e|
          safe_get(pom, "/project/#{e}")
        end.join(':')

        raise("#{id}: #{x.message}")
      end

      def essentials
        { group: group, artifact: artifact, version: version }
      end

      def files
        file = artifact_filename

        {
          url: maven_url(repo, group, artifact, file),
          filename: File.basename(file),
          sha1: read(maven_url(repo, group, artifact, file + '.sha1'))
        }
      end

      def artifact_filename
        file = "#{version}/#{artifact}-#{version}"
        file += "-#{classifier}" if classifier && !classifier.empty?
        file + '.jar' # TODO, packaging
      end

      ## Utils

      # Try get node text by xpath. Returns nil if no such node
      def safe_get(elem, xpath)
        t = elem.elements[xpath]
        return unless t

        t.text
      end

      def read_pom(repo, group, artifact, version)
        pom_file = "#{version}/#{artifact}-#{version}.pom"
        url = maven_url(repo, group, artifact, pom_file)
        pom_bytes = read(url)
        REXML::Document.new(pom_bytes)
      rescue StandardError => _x
        raise "Can't read pom from url: #{url} "
      end
    end
    # Finds and downloads all specified maven artifacts with transitive
    # dependencies.
    # Usage:
    # ```ruby
    #    # Create maven resolver with options. For expample request javadoc too
    #   mvn = Resolver.new(javadoc: true)
    #   mvn.add_lib group: org.junit.jupiter,
    #               artifact: junit-juptier-api,
    #               version: 5.3.1
    #   mvn.add_lib group: org.junit.jupiter,
    #               artifact: junit-juptier-engine,
    #               version: 5.3.1
    #   mvn.add_lib group: org.junit.jupiter,
    #               artifact: junit-juptier-params,
    #               version: 5.3.1
    #   mvn.fetch('libs') # Download all artifacts to libs directory
    # ```
    class Resolver
      class << self
        # Parses library string according to Maven coordinates rules
        # @param artifact [String] artifact string in Maven coordinates
        def parse_lib(artifact)
          # Simple artifact string resolution. It may be much more complex
          g, a, v = artifact.split(':')
          { group: g, artifact: a, version: v || :latest }
        end
      end

      include Commons

      # Predefined repository names
      REPOSITORIES = {
        central: 'https://repo.maven.apache.org/maven2',
        jcenter: 'https://jcenter.bintray.com',
        local: "file://#{File.expand_path('~/.m2/repository')}"
      }.freeze
      # Metadata file for maven artifact. It contains information about artifact
      # versions
      METADATA_FILE = 'maven-metadata.xml'.freeze
      # @opt repos [Array<String, Symbol>] list of repository URI for
      #   artifact lookup. List may contain either String or Symbol elements.
      #   Symbol elements are used as logical name for known maven repostiories.
      #   * :central - https://repo.maven.apache.org/maven2/
      #   * :jcenter - https://jcenter.bintray.com/
      #   * :local - $HOME/.m2
      #
      # @opt sources [Boolean] download sources
      # @opt javadoc [Boolean] download javadoc
      def initialize(repos: [:central], sources: false, javadoc: false)
        raise 'No repositories provided' unless repos && !repos.empty?

        @repositories = resolve_repos(repos)

        @sources = sources
        @javadoc = javadoc

        @targets = []
      end

      # Adds library for dependency resolution. This allows us to build
      # dependency which consists of multiple roots.
      # @param group [String] groupId
      # @param artifact [String] artifactId
      # @param version [String, Symbol] artifact version  or :latest
      def add_lib(group:, artifact:, version: :latest)
        @targets << { group: group, artifact: artifact, version: version }
      end

      # Finds all requested artifacts without downloading them.
      def resolve
        @resolved = @targets.map do |target|
          resolve_target(target)
        end
      end

      def dump(file)
        File.open(file, 'w') do |f|
          obj = JSON.parse(@resolved.to_json)
          f.write(YAML.dump(obj))
        end
      end

      # Walk through graph and mark some targets for downloading then download
      # them. Dependencies should be traversed in breadth-first way. To ensure
      # that we'll get propper version resolving when artifact appears in
      # dependency graph multiple times. As of maven documentation:
      #   Maven picks the "nearest definition". That is, it uses the version of
      #   the closest dependency to your project in the tree of dependencies.
      #   You can always guarantee a version by declaring it explicitly in your
      #   project's POM. Note that if two dependency versions are at the same
      #   depth in the dependency tree, the first declaration wins.
      # @see https://maven.apache.org/guides/introduction/introduction-to-dependency-mechanism.html
      # @param dir [String] output directory
      def fetch(dir)
        dependency_graph = resolve

        # List of targets to visit next
        open_set = [] + dependency_graph
        # Hash of targets to download. Whe keep [group, artifact] => %target%
        # mappings, to check if we need add this node to download list
        targets = {}
        until open_set.empty?
          n = open_set.shift
          open_set += n[:dependencies]

          id = n[:artifact].values_at(:group, :artifact)
          # Don't add artifact if already have version for it
          targets[id] = n unless targets.key?(id)
        end

        # Download all listed targets
        targets.each do |_id, target|
          artifact = target[:artifact]
          # Generate list of files to download
          files = [].tap do |t|
            t << describe_target(target[:repo], artifact)
            t << describe_target(target[:repo], artifact, classifier: 'sources') if sources?
            t << describe_target(target[:repo], artifact, classifier: 'javadoc') if javadoc?
          end

          files.each do |f|
            Grably.fetch(f[:url], dir, filename: f[:filename], log: false)
          end
        end
      end

      def sources?
        @sources
      end

      def javadoc?
        @javadoc
      end

      private

      def resolve_target(target)
        # Walk through all listed repositories and find one containing our lib
        repository = @repositories.find do |r|
          metadata?(r, target[:group], target[:artifact])
        end

        raise "Can't find #{target.inspect}" unless repository

        # now all dependencies for that target expected to be in same repository
        # as we found base artifact
        resolve_target_with_repo(target, repository, {})
      end

      def scope_matches?(scope)
        scope == 'compile'
      end

      def resolve_target_with_repo(target, repo, cached, excludes = []) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        group, artifact, version, classifier =
          target.values_at(:group, :artifact, :version, :classifier)
        id = "#{group}:#{artifact}:#{version}-#{classifier}"
        if cached.key?(id)
          art = cached[id]
        else
          if version == '*'
            # TODO: Correct versioning. We cant just sort because of SNAPSHOT,
            # RC, MC, etc.
            metadata_bytes = read(maven_url(repo, group, artifact, METADATA_FILE))

            # Read metadata file to get version
            metadata = REXML::Document.new(metadata_bytes)
            versions = metadata.elements
                               .to_a('/metadata/versioning/versions/*')
                               .map(&:text)
            version = versions.max_by { |v|  Version.new(v) }
            warn "Wildcard version #{group}:#{artifact}. Will use #{version}"
          elsif version =~ /\$\{.+\}/
            raise "Can't handle template verions: #{version}"
          end

          # Version found. Now we need to get all dependencies and resolve them
          # too. Read pom add fetch all dependencies (compile + runtime)
          art = ArtifactReader.new(repo, group, artifact, version, classifier)
                              .read_artifact
        end

        excludes += art[:exclusions]
        # Update cache
        cached[id] = art
        # Scan all dependencies recursievly.
        deps = art[:dependencies]
               .select { |d| scope_matches?(d[:scope]) && !d[:optional] }
               .reject { |d| excludes.include?(d.values_at(:group, :artifact)) }
               .map { |d| resolve_target_with_repo(d, repo, cached, excludes) }

        # Update dependencies and return
        # This is node in dependency graph. We will use this to describe all
        # relations between libraries. It usefull for dependency tree
        # illustration too
        art.merge(dependencies: deps)
      end

      def describe_target(repo, target, overrides = {})
        real = {}.merge!(target).merge!(overrides)
        group, artifact, version, classifier =
          real.values_at(:group, :artifact, :version, :classifier)

        file = "#{version}/#{artifact}-#{version}"
        file += "-#{classifier}" if classifier && !classifier.empty?
        file += '.jar' # TODO, packaging

        {
          group: group,
          artifact: artifact,
          version: version,

          url: maven_url(repo, group, artifact, file),
          filename: File.basename(file),
          sha1: read(maven_url(repo, group, artifact, file + '.sha1'))
        }
      end

      def metadata?(repo, group, artifact)
        url = URI.parse(maven_url(repo, group, artifact, METADATA_FILE))
        req = Net::HTTP.new(url.host, url.port)
        req.use_ssl = true if repo =~ /^https:/
        res = req.request_head(url.path)

        res.code == '200'
      end

      def read(url)
        url = URI.parse(url)
        Net::HTTP.get(url)
      end

      def maven_url(repo, group, artifact, rest)
        "#{repo}/#{group.tr('.', '/')}/#{artifact}/#{rest}"
      end

      def target_string(target)
        target.values_at(%i(group artifact version)).join(':')
      end

      def resolve_repos(repos)
        repos.map do |r|
          if r.is_a?(Symbol)
            raise "Unknown repository alias: #{r}" unless REPOSITORIES.key?(r)

            REPOSITORIES[r]
          else
            r
          end
        end
      end
    end
  end
end
