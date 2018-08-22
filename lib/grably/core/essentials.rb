module Grably # :nodoc:
  # Short OS family name
  # :win - Windows
  # :linux - Linux
  # :mac - OS X
  PLATFORM = case RUBY_PLATFORM
             when /mingw/, /cygwin/
               :windows
             when /mac/, /darwin/
               :mac
             else
               :linux
             end
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

  class << self
    %w(windows mac linux).each do |platform|
      # rubocop:disable Security/Eval
      eval("def #{platform}?; #{PLATFORM == platform} end")
      # rubocop:enable Security/Eval
    end

    def cores_number
      CORES_NUMBER
    end
  end
end
