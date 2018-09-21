module Grably # :nodoc:
  class IdeaModuleJob # :nodoc:
    include Grably::Job

    require 'rexml/document'

    srcs :libs
    opt :srcs
    opt :exclude
    opt :mods
    opt :name
    opt :lang_level

    # :libs - set of libraries, export is determined for each library from product's meta
    # :srcs - description of sources folders (array), each element looks like:
    #         { path: путь, test: false|true, type: :java|:res|:resources }
    #         test - if omitted then false
    #         type - if omitted then java
    # :exclude - list of exclude folders
    # :mods - array of dependent modules, each entry looks like:
    #         { name: <module_name>, export: true|false }
    #         export is true if omitted
    # :name - module name, .iml name will be same
    # :lang_level - language level, optional
    def setup(p = {})
      p = p.clone

      @libs = p.delete(:libs)
      @srcs = p.delete(:srcs)
      @exclude = p.delete(:exclude)
      @mods = p.delete(:mods)
      @name = p.delete(:name)
      @lang_level = p.delete(:lang_level)

      raise "unknown options: #{p.inspect}" unless p.empty?
    end

    def changed?
      true
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
    def build
      base_iml = "#{@name}.iml"

      doc = REXML::Document.new
      doc.context[:attribute_quote] = :quote

      mod = doc.add_element 'module', 'type' => 'JAVA_MODULE', 'version' => '4'
      root = mod.add_element 'component', 'name' => 'NewModuleRootManager', 'inherit-compiler-output' => 'true'
      root.attributes['LANGUAGE_LEVEL'] = @lang_level if @lang_level
      root.add_element 'exclude-output'

      content = root.add_element 'content', 'url' => 'file://$MODULE_DIR$'

      srcs = @srcs || []
      srcs = [srcs] unless srcs.is_a? Array
      srcs.each do |src|
        src = { path: src } unless src.is_a? Hash
        is_test = src[:test]
        is_test = false if is_test.nil?
        type = src[:type] || :java
        path = src[:path]
        e = { 'url' => "file://$MODULE_DIR$/#{path}" }
        if type == :java
          e['isTestSource'] = is_test.to_s
        elsif %i(res resources).include?(type)
          e['type'] = is_test ? 'java-test-resource' : 'java-resource'
        else
          raise "unknown source type: #{type}"
        end
        content.add_element 'sourceFolder', e
      end

      excl = @exclude || []
      excl = [excl] unless excl.is_a? Array
      excl.each do |path|
        content.add_element 'excludeFolder', 'url' => "file://$MODULE_DIR$/#{path}"
      end

      root.add_element 'orderEntry', 'type' => 'inheritedJdk'
      root.add_element 'orderEntry', 'type' => 'sourceFolder', 'forTests' => 'false'

      mods = @mods || []
      mods = [mods] unless mods.is_a? Array
      mods.each do |m|
        m = { name: m } unless m.is_a? Hash
        name = m[:name]
        export = m[:export]
        export = true if export.nil?
        e = { 'type' => 'module', 'module-name' => name }
        e['exported'] = '' if export
        root.add_element 'orderEntry', e
      end

      cur_path = File.expand_path(File.dirname(base_iml))
      libs = @libs.map do |lib|
        next unless lib.src.end_with?('.jar', '.zip')

        jar_path = File.expand_path(lib.src)
        src_path = lib[:src].src
        src_path = File.expand_path(src_path) unless src_path.nil?

        jar_path = Pathname.new(jar_path).relative_path_from(Pathname.new(cur_path)).to_s
        src_path = Pathname.new(src_path).relative_path_from(Pathname.new(cur_path)).to_s unless src_path.nil?

        { jar: jar_path, src: src_path, export: lib[:export] }
      end

      libs.compact!
      libs.sort! { |l1, l2| l1[:jar] <=> l2[:jar] }

      libs.each do |lib|
        jar_path = lib[:jar]
        src_path = lib[:src]

        e = { 'type' => 'module-library' }
        e['exported'] = '' if lib[:export]
        entry = root.add_element 'orderEntry', e
        lib = entry.add_element 'library', 'name' => Pathname.new(jar_path).basename
        lib.add_element('CLASSES').add_element('root', 'url' => "jar://$MODULE_DIR$/#{jar_path}!/")
        lib.add_element('JAVADOC')
        sources = lib.add_element('SOURCES')
        sources.add_element('root', 'url' => "jar://$MODULE_DIR$/#{src_path}!/") unless src_path.nil?
      end

      iml = job_path("#{@name}.iml")
      File.open(iml, 'w') do |f|
        f.puts '<?xml version="1.0" encoding="UTF-8"?>'
        REXML::Formatters::Pretty.new(2, true).write(doc, f)
      end
      FileUtils.cp(iml, base_iml)

      iml
    end
  end
end
