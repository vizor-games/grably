require 'ffi'

module WinColors # :nodoc:
  extend FFI::Library
  ffi_lib 'kernel32.dll'

  class Coord < FFI::Struct # :nodoc:
    layout :x, :short,
           :y, :short
  end

  class SmallRect < FFI::Struct # :nodoc:
    layout :left, :short,
           :top, :short,
           :right, :short,
           :bottom, :short
  end

  class ConsoleScreenBufferInfo < FFI::Struct # :nodoc:
    layout :size, Coord,
           :cursor_position, Coord,
           :attributes, :uint32,
           :window, SmallRect,
           :max_window_size, Coord
  end

  attach_function :GetConsoleMode, %i(pointer pointer), :int
  attach_function :SetConsoleMode, %i(pointer uint64), :int
  attach_function :GetStdHandle, %i(uint64), :pointer
  attach_function :GetLastError, [], :uint64
  attach_function :SetConsoleTextAttribute, %i(pointer uint64), :int
  attach_function :GetConsoleScreenBufferInfo, %i(pointer pointer), :int

  # MSDN:
  #   The standard output device. Initially, this is the active console screen
  #   buffer, CONOUT$.
  STD_OUTPUT_HANDLE = -11

  # MSDN:
  #   The standard error output device.
  STD_ERROR_HANDLE = -12

  class << self
    def redirect_outputs
      Kernel.module_exec do
        remove_method :putc
        def putc(c)
          $stdout.puc(c)
        end
      end

      output_handle = GetStdHandle(STD_OUTPUT_HANDLE)
      $stdout = AnsiParser.new($stdout, output_handle, 1) if get_console_mode(output_handle) < 32

      error_handle = GetStdHandle(STD_ERROR_HANDLE)
      $stderr = AnsiParser.new($stderr, error_handle, 2) if get_console_mode(error_handle) < 32
    end

    def get_console_mode(handle)
      m = FFI::MemoryPointer.new(:uint64, 1)
      WinColors.GetConsoleMode(handle, m)
      m.read_long
    end
  end

  # :nodoc:
  class AnsiParser < IO
    ANSI2WIN = [0, 4, 2, 6, 1, 5, 3, 7].freeze

    def initialize(out, handle, fd) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      super(fd, 'w')

      @out = out
      @handle = handle

      info = ConsoleScreenBufferInfo.new
      WinColors.GetConsoleScreenBufferInfo(@handle, info)

      @attrs = info[:attributes]
      @default_foreground = @attrs & 0x07
      @default_background = (@attrs >> 4) & 0x07
      @default_bold = (@attrs & 0x08) != 0
      @default_underline = (@attrs & 0x400) != 0

      reset_colors

      @buffer = []

      Kernel.at_exit do
        WinColors.SetConsoleTextAttribute(@handle, @attrs)
      end
    end

    def reset_colors
      @foreground = @default_foreground
      @background = @default_background
      @bold = @default_bold
      @underline = @default_underline
      @revideo = false
      @concealed = false
    end

    def putc(c) # rubocop:disable Metrics/MethodLength
      c = c.ord
      if @buffer.empty?
        # match \e
        if c == 27
          @buffer << int
        else
          write(int.chr)
        end
      else
        @buffer << c
        case c
          # match m, J, L, M, @, P, A, B, C, D, E, F, G, H, f, s, u, U, K, X
        when 109, 74, 76, 77, 64, 80, 65, 66, 67, 68,
            69, 70, 71, 72, 102, 115, 117, 85, 75, 88
          write(@buffer.pack('c*'))
          @buffer.clear
        end
      end
    end

    def write(*s)
      s.each { |l| print_string(l) }
    end

    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength, Metrics/PerceivedComplexity
    # rubocop:disable Metrics/BlockNesting, Metrics/BlockLength
    def print_string(s)
      s = s.to_s.dup
      until s.empty?
        if s.sub!(/([^\e]*)?\e([\[\(])([0-9\;\=]*)([a-zA-Z@])(.*)/, '\5')
          @out.write(concealed(Regexp.last_match(1)))
          if Regexp.last_match(2) == '[' && Regexp.last_match(4) == 'm'
            attrs = Regexp.last_match(3).split(';')
            attrs.push(nil) unless attrs
            attrs.each do |attr|
              atv = attr.to_i
              case atv
              when 0
                reset_colors
              when 1
                @bold = true
              when 21
                @bold = false
              when 4
                @underline = true
              when 24
                @underline = false
              when 7
                @revideo = true
              when 27
                @revideo = false
              when 8
                @concealed = true
              when 28
                @concealed = false
              when 30..37
                @foreground = ANSI2WIN[atv - 30]
              when 39
                @foreground = @default_foreground
              when 40..47
                @background = ANSI2WIN[atv - 40]
              when 49
                @background = @default_background
              end
            end

            attrib = @revideo ? (@background | (@foreground << 4)) : (@foreground | (@background << 4))
            attrib |= 0x08 if @bold
            attrib |= 0x400 if @underline

            WinColors.SetConsoleTextAttribute(@handle, attrib)
          end
        else
          @out.write(concealed(s))
          s = ''
        end
      end
    end

    def concealed(s)
      @concealed ? s.gsub(/\S/, ' ') : s
    end
  end
end
