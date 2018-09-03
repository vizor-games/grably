module Grably
  module Java # :nodoc:
    module_function

    def detect_jdk # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/LineLength
      jdk_home = ENV['__GRABLY_JDK__']
      java_target = ENV['__GRABLY_JAVA_TARGET__']

      unless jdk_home && java_target
        log_msg "Detecting JDK's".yellow

        javac = windows? ? 'javac.exe' : 'javac'

        javahome_lines = [
          'java',
          '-cp', File.join(File.dirname(__FILE__), 'javahome'),
          'JavaHome'
        ].run

        jdk_home, java_target = javahome_lines.split("\n")

        jdk_home = File.expand_path(jdk_home)
        unless File.exist?(File.join(jdk_home, 'bin', javac))
          if File.exist?(File.join(jdk_home, '..', 'bin', javac))
            jdk_home = File.expand_path(File.join(jdk_home, '..'))
          else
            # rubocop:disable Metrics/BlockNesting
            java = windows? ? 'java.exe' : 'java'
            raise "No JDK found, but found JRE: #{jdk_home}" if File.exist?(File.join(jdk_home, 'bin', java))
            raise 'No JDK found'
          end
        end
      end

      ENV['__GRABLY_JDK__'] = jdk_home
      ENV['__GRABLY_JAVA_TARGET__'] = java_target

      java_target = c.java_target || ENV['java_target'] || java_target
      java_source = c.java_source || ENV['java_source'] || java_target

      [jdk_home, java_target, java_source]
    end

    def jdk_env
      { 'JAVA_HOME' => JDK_HOME, 'JAVAC' => File.join(JDK_HOME, 'bin', 'javac') }
    end

    def java_cmd(p = {})
      p = p.clone
      cmd = [jdk_env, File.join(JDK_HOME, 'bin', 'java')]
      cmd << "-Xmx#{p.delete(:max_mem)}" if p[:max_mem]

      # Sometimes we need to launch apps with ui on build.
      # By default non mac java uses headless=false while mac java uses headless=true.
      # So it's better for us to make it same for all platforms.
      cmd << '-Djava.awt.headless=false' if mac?

      cmd << '-Dfile.encoding=UTF8' if windows?
      raise "unknown options: #{p.inspect}" unless p.empty?
      cmd
    end

    def javac_cmd(p = {}) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/LineLength
      p = p.clone
      source_version = p.delete(:source) || JAVA_SOURCE
      target_version = p.delete(:target) || JAVA_TARGET
      max_mem = p.delete(:max_mem)
      raise "unknown options: #{p.inspect}" unless p.empty?
      cmd = [jdk_env, File.join(JDK_HOME, 'bin', 'javac')]
      cmd += ["-J-Xmx#{max_mem}"] if max_mem
      cmd += ['-target', target_version] if target_version
      cmd += ['-source', source_version] if source_version
      cmd += %w(-encoding UTF8) unless linux?
      cmd
    end

    def java_classpath(srcs)
      srcs = [srcs] unless srcs.is_a?(Array)
      srcs = srcs.map { |s| s.is_a?(Product) ? s.src : s }
      srcs.join(File::PATH_SEPARATOR)
    end

    def java_slot(target = JAVA_TARGET)
      ['java', target]
    end

    def java_binary_slot
      %w(java binary)
    end

    def java_virtual_slot
      %w(java virtual)
    end

    JDK_HOME, JAVA_TARGET, JAVA_SOURCE = detect_jdk
    JRE_HOME = File.join(JDK_HOME, 'jre')

    log_msg "Using JDK: #{JDK_HOME}, target: #{JAVA_TARGET}, source: #{JAVA_SOURCE}"
  end
end
