module Grably
  COLOR_CODES = {
    normal: 0,
    bright: 1,
    light: 1, # light is synonym for bright for us
    dim: 2,
    underscore: 4,
    blink: 5,
    reverse: 7,
    hidden: 8,

    black: 30,
    red: 31,
    green: 32,
    yellow: 33,
    blue: 34,
    magenta: 35,
    cyan: 36,
    white: 37,
    default: 39,

    bg_black: 40,
    bg_red: 41,
    bg_green: 42,
    bg_yellow: 43,
    bg_blue: 44,
    bg_magenta: 45,
    bg_cyan: 46,
    bg_white: 47,
    bg_default: 49
  }.freeze

  # Contains escape symbols for colors representation in *nix shells.
  # If used adds coloring methods to String object. This module is intendet to
  # be included in String class
  module ShellColors
    class << self
      # Generates color codes sequence to create color effect
      # @param [String | Symbol] args color settigns
      # @return [String] color control sequence
      def color(*args)
        codes = args.map { |a| COLOR_CODES[a.to_sym] }.compact
        "\e[#{codes.join(';')}m"
      end
    end

    # Color code sequence which resets colors to default state. Which is
    # normal (0), default (39) and bg_default (49)
    COLOR_RESET = color(:normal, :default, :bg_default)

    def color(*args)
      Grably::ShellColors.color(*args)
    end

    # This generates color methods inside module. When module is included all of
    # them will be included too
    COLOR_CODES.each_key do |color_key|
      # rubocop:disable Security/Eval
      eval("def #{color_key}; color(:#{color_key}) + to_s + \"#{COLOR_RESET}\"; end")
      # rubocop:enable Security/Eval
    end
  end

  # Fake colors module. Generates no-op methods for string color modifications
  module FakeColors
    class << self
      # This generates color methods inside module. When module is included all of
      # them will be included too
      COLOR_CODES.each_key do |color_key|
        # rubocop:disable Security/Eval
        eval("def #{color_key}; self; end")
        # rubocop:enable Security/Eval
      end
    end
  end
end

# Grably specific String extensions
class String
  case Grably::PLATFORM
  when :linux, :mac
    include Grably::ShellColors
  else
    include Grably::FakeColors
  end
end
