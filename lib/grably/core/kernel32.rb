require 'fiddle'
require 'fiddle/types'
require 'fiddle/import'

# Binding to kernel32.dll functions
# TODO extern calls will be nicer if we can include Fiddle::Win32Types. But I
#      can't determine how to do it properly right now.
module Kernel32
  extend Fiddle::Importer

  dlload('kernel32.dll')
  # If the function succeeds, the return value is nonzero.
  # If the function fails, the return value is zero. To get extended error
  # information, call GetLastError.
  extern 'int SetConsoleMode(uintptr_t, unsigned long)'
  extern 'unsigned long GetStdHandle(unsigned long)'
  extern 'unsigned long GetLastError()'

  # MSDN:
  #   Characters written by the WriteFile or WriteConsole function or echoed by
  #   the ReadFile or ReadConsole function are examined for ASCII control
  #   sequences and the correct action is performed. Backspace, tab, bell,
  #   carriage return, and line feed characters are processed.
  ENABLE_PROCESSED_OUTPUT = 0x0001

  # MSDN:
  #   When writing with WriteFile or WriteConsole or echoing with ReadFile or
  #   ReadConsole, the cursor moves to the beginning of the next row when it
  #   reaches the end of the current row. This causes the rows displayed in the
  #   console window to scroll up automatically when the cursor advances beyond
  #   the last row in the window. It also causes the contents of the console
  #   screen buffer to scroll up (discarding the top row of the console screen
  #   buffer) when the cursor advances beyond the last row in the console screen
  #   buffer. If this mode is disabled, the last character in the row is
  #   overwritten with any subsequent characters.
  ENABLE_WRAP_AT_EOL_OUTPUT = 0x0002

  # MSDN:
  #   When writing with WriteFile or WriteConsole, characters are parsed for
  #   VT100 and similar control character sequences that control cursor
  #   movement, color/font mode, and other operations that can also be performed
  #   via the existing Console APIs. For more information, see
  #   Console Virtual Terminal Sequences.
  ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004

  # Combination of flags which determines if we can use ansi colors in terminal
  ANSI_SUPPORT = ENABLE_PROCESSED_OUTPUT |
                 ENABLE_WRAP_AT_EOL_OUTPUT |
                 ENABLE_VIRTUAL_TERMINAL_PROCESSING

  # MSDN:
  #   The standard output device. Initially, this is the active console screen
  #   buffer, CONOUT$.
  STD_OUTPUT_HANDLE = -11

  class << self
    # Use syscall to determine if console supports ANSI colors output
    def ansi_colors?
      stdout_handle = GetStdHandle(STD_OUTPUT_HANDLE)
      # If SetConsoleMode returns nonzero operation was successful. So we can
      # use ansi colors
      Kernel32.SetConsoleMode(stdout_handle, ANSI_SUPPORT) != 0
    end
  end
end
