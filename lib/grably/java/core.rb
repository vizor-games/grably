module Grably
  module Java # :nodoc:
    module_function

    WHICH_JAVA_CMD = [
      'java',
      '-cp', File.join(File.dirname(__FILE__), 'javahome'),
      'JavaHome'
    ].freeze

    JAVAC = windows? ? 'javac.exe' : 'javac'
    JAVA = windows? ? 'java.exe' : 'java'

    JDK_ENV_KEY = '__GRABLY_JDK__'.freeze
    JAVA_TARGET_ENV_KEY = '__GRABLY_JAVA_TARGET__'.freeze

    private_constant :WHICH_JAVA_CMD
    private_constant :JAVAC
    private_constant :JAVA

    private_constant :JDK_ENV_KEY
    private_constant :JAVA_TARGET_ENV_KEY

    def javac
      JAVAC
    end

    def detect_jdk # rubocop:disable Metrics/CyclomaticComplexity
      jdk_home = ENV[JDK_ENV_KEY]
      java_target = ENV[JAVA_TARGET_ENV_KEY]

      unless jdk_home || java_target
        jdk_home, java_target = which_java
        ENV[JDK_ENV_KEY] = jdk_home
        ENV[JAVA_TARGET_ENV_KEY] = java_target
      end

      java_target = c.java_target || ENV['java_target'] || java_target
      java_source = c.java_source || ENV['java_source'] || java_target

      [jdk_home, java_target, java_source]
    end

    def which_java
      log_msg "Detecting JDK's".yellow
      jdk_home, java_target = WHICH_JAVA_CMD.run.split("\n")

      jdk_home = File.expand_path(jdk_home)
      jdk_home = check_jdk_home(jdk_home) unless File.exist?(File.join(jdk_home, 'bin', javac))

      [jdk_home, java_target]
    end

    def check_jdk_home(jdk_home)
      if File.exist?(File.join(jdk_home, '..', 'bin', javac))
        File.expand_path(File.join(jdk_home, '..'))
      else
        raise "No JDK found, but found JRE: #{jdk_home}" if File.exist?(File.join(jdk_home, 'bin', JAVA))
        raise 'No JDK found'
      end
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
      [srcs].flatten.compact.map { |s| s.is_a?(Product) ? s.src : s }.join(File::PATH_SEPARATOR)
    end

    alias classpath java_classpath
  end
end
