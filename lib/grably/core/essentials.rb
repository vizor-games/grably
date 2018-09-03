require 'rbconfig'

module Grably # :nodoc:
  # Keeps value of RbConfig::CONFIG['host_os']
  HOST_OS = RbConfig::CONFIG['host_os']
  # Keeps short os name. It suppoused to be exact host OS name, not ruby
  # platform.
  # Possible values are: :windows, :mac, :linux.
  # Other OSes may be unsupported.
  PLATFORM = case HOST_OS
             when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
               :windows
             when /darwin|mac os/
               :mac
             when /linux/
               :linux
             when /solaris|bsd/
               :unix
             else
               raise "Unknown host OS: #{HOST_OS}"
             end

  # Keeps mark if we running with jruby interpreter
  JRUBY = RUBY_PLATFORM == 'java'

  # Number of CPU cores
  CORES_NUMBER =
    case PLATFORM
    when :windows
      # this works for windows 2000 or greater
      require 'win32ole'
      wmi = WIN32OLE.connect('winmgmts://')
      query = 'select * from Win32_ComputerSystem'
      wmi.ExecQuery(query).each do |system|
        begin
          processors = system.NumberOfLogicalProcessors
        rescue StandardError => x
          puts 'Warn: ' + x.message
          processors = 1
        end
        return [system.NumberOfProcessors, processors].max
      end
    when :mac
      `sysctl -n hw.logicalcpu`.to_i
    when :linux
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    else
      raise "can't determine 'number_of_processors' for '#{RUBY_PLATFORM}'"
    end

  %i(windows mac linux).each do |platform|
    # rubocop:disable Security/Eval
    eval("def #{platform}?; #{PLATFORM == platform} end")
    # rubocop:enable Security/Eval
  end

  # Tells if we running with jruby interpreter
  def jruby?
    JRUBY
  end

  def cores_number
    CORES_NUMBER
  end
end
