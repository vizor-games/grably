require 'rbconfig'

module Grably # :nodoc:
  # Functions to provide essential values like CORES_NUMBER, Ruby Platform,
  # and Host OS
  module Essentials
    # Keeps value of RbConfig::CONFIG['host_os']
    HOST_OS = RbConfig::CONFIG['host_os']

    class << self
      def detect_host_os(hots_os_string = Essentials::HOST_OS) # rubocop:disable Metrics/MethodLength
        case hots_os_string
        when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          :windows
        when /darwin|mac os/
          :mac
        when /linux/
          :linux
        when /solaris|bsd/
          :unix
        else
          raise "Unknown host OS: #{hots_os_string}"
        end
      end

      # Tries to detect number of available cores. If fails uses default cores
      # count and prints warning message. For *nix systems result might be
      # smaller number than physical cpus.
      # @see Grably::Essentials.detect_cpu_cores_nix for more details
      # @return [Integer] nubmer of available cores or default value
      def detect_cpu_cores(platform, default_cores_count = 4)
        case platform
        when :windows
          detect_cpu_cores_win
        when :linux, :mac
          detect_cpu_cores_nix
        end
      rescue LoadError
        warn "Can't detect number of CPUs for sure. " \
             "Using default: #{default_cores_count}"
        default_cores_count
      end

      def detect_cpu_cores_win
        # this works for windows 2000 or greater
        require 'win32ole'
        wmi = WIN32OLE.connect('winmgmts://')
        query = 'select * from Win32_ComputerSystem'
        wmi.ExecQuery(query).each do |system|
          processors = system.NumberOfLogicalProcessors
          return [system.NumberOfProcessors, processors].max
        end
      end

      # Get number of cores for *nix systems. This uses etc module to detect
      # number of cores.
      # Note from etc implementation:
      #  The result might be smaller number than physical cpus especially when
      #  ruby process is bound to specific cpus. This is intended for getting
      #  better parallel processing.
      def detect_cpu_cores_nix
        # On Unix platforms trying to use etc module to determine accessible
        # number of cores
        require 'etc'
        Etc.nprocessors
      end

      def jruby?(ruby_platform = RUBY_PLATFORM)
        ruby_platform == 'java'
      end
    end
  end

  private_constant :Essentials
  # Keeps short os name. It suppoused to be exact host OS name, not ruby
  # platform.
  # Possible values are: :windows, :mac, :linux.
  # Other OSes may be unsupported.
  PLATFORM = Essentials.detect_host_os

  # Keeps mark if we running with jruby interpreter
  JRUBY = Essentials.jruby?

  # Number of CPU cores
  CORES_NUMBER = Essentials.detect_cpu_cores(PLATFORM)

  %i(windows mac linux).each do |platform|
    eval("def #{platform}?; #{PLATFORM == platform} end") # rubocop:disable Security/Eval
  end

  # Tells if we running with jruby interpreter
  def jruby?
    JRUBY
  end

  def cores_number
    CORES_NUMBER
  end
end
