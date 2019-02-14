require 'net/http'
require 'rexml/document'

module Grably
  # Utitities to work with maven repositories
  module Maven
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
        raise 'No repositories provided' unless repos && repos.length > 0
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
        resolved = {}
        @targets.each do |target|
          resolve_target(target, resolved)
        end

        resolved
      end

      # Downloads all transitive dependencies to specified directory
      # @param dir [String] output directory
      def fetch(dir)
        fetch_targets = resolve
        fetch_targets.each do |k, files|
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

      def resolve_target(target, resolved)
        id = target.values_at(%i(group artifact))
        return resolved if resolved.key?(id)

        # Walk through all listed repositories and find one containing our lib
        repository = @repositories.find do |r|
          metadata?(r, target[:group], target[:artifact])
        end

        raise "Can't find #{target.inspect}" unless repository

        # now all dependencies for that target expected to be in same repository
        # as we found base artifact
        resolve_target_with_repo(target, repository, resolved)
      end

      def scope_matches?(scope)
        scope == 'compile'
      end

      def resolve_target_with_repo(target, repo, resolved) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        group, artifact, version, classifier =
          target.values_at(*%i(group artifact version classifier))
        # Skip artifact if it was already resolved. As far as we are using first
        # dependency version we met in graph we don't check it.
        return if resolved.key?([group, artifact])

        metadata_bytes = read(maven_url(repo, group, artifact, METADATA_FILE))

        # Read metadata file to get version
        metadata = REXML::Document.new(metadata_bytes)
        versions = metadata.elements
                           .to_a('/metadata/versioning/versions/*')
                           .map(&:text)
        if version == '*'
          # TODO: Correct versioning. We cant just sort because of SNAPSHOT,
          # RC, MC, etc.
          version = versions.max
          warn "Wildcard version #{group}:#{artifact}. Will use #{version}"
        elsif !versions.include?(version)
          raise "Can't find version #{version} for #{group}:#{artifact} in #{repo}" \
                "Available versions: #{versions.join(', ')}"
        end

        # Hooray! Version found. Now we need to get all dependencies and resolve
        # them too. Read pom add fetch all dependencies (compile + runtime)
        pom_file = "#{version}/#{artifact}-#{version}.pom"
        pom_bytes = read(maven_url(repo, group, artifact, pom_file))
        pom = REXML::Document.new(pom_bytes)

        # List all direct dependencies. Ususaly we insterested in two types of
        # dependencies:
        # - runtime
        # - compile
        # Now fetch compile only
        dependencies = pom.elements.to_a('/project/dependencies/*').map do |dep|
          {
            group: dep.elements['./groupId'].text,
            artifact: dep.elements['./artifactId'].text,
            version: dep.elements['./version']&.text || '*',
            scope: dep.elements['./scope']&.text || 'sompile'
          }
        end

        resolved[[group, artifact]] = [].tap do |t|
          t << describe_target(repo, target, version: version)
          t << describe_target(repo, target, version: version, classifier: 'sources') if sources?
          t << describe_target(repo, target, version: version, classifier: 'javadoc') if javadoc?
        end

        dependencies
          .select { |d| scope_matches?(d[:scope]) }
          .each { |d| resolve_target_with_repo(d, repo, resolved) }
      end

      def describe_target(repo, target, overrides = {})
        real = {}.merge!(target).merge!(overrides)
        group, artifact, version, classifier =
          real.values_at(*%i(group artifact version classifier))

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
