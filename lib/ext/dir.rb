require 'pathname'

# Special grably dir extensions
class Dir
  class << self
    # Naive implementation of Dir.glob relative to base directory. Default
    # implementation of Dir.glob with base: argument was introduced in ruby
    # 2.5.0
    def glob_base_pre25(pattern, base) # rubocop:disable Metrics/AbcSize
      # This should cover exceptional cases for base argument like: nil, '', '.'
      return glob(pattern) if base.nil? || !File.exist?(base)
      # Here we use fact that absolute_path just manipulates with content of
      # its argument without invoking real file system. So we can safely try
      # to get absolute path of glob pattern.
      return glob(pattern) if File.absolute_path(pattern) == pattern

      base = Pathname.new(base)
      glob(File.join(base, pattern)).map do |p|
        result = Pathname.new(p).relative_path_from(base).to_s
        result += File::SEPARATOR unless File.file?(p)
        result
      end
    end

    def glob_base_25(pattern, base)
      glob(pattern, base: base)
    end

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.5.0')
      alias glob_base glob_base_pre25
    else
      alias glob_base glob_base_25
    end
  end
end
