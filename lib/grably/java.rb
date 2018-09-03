# java support
require_relative('java/core')

module Grably
  module Java # :nodoc:
    JDK_HOME, JAVA_TARGET, JAVA_SOURCE = detect_jdk
    JRE_HOME = File.join(JDK_HOME, 'jre')

    log_msg "Using JDK: #{JDK_HOME}, target: #{JAVA_TARGET}, source: #{JAVA_SOURCE}"
  end
end

# jobs
require_relative('java/javac')
require_relative('java/manifest')
require_relative('java/jar')
