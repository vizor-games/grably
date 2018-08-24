require 'pathname'

# Special grably dir extensions
class Dir
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.5.0')
    def self.glob_base(pattern, base)
      base = Pathname.new(base)
      Dir.glob(File.join(base, pattern)).map { |p| Pathname.new(p).relative_path_from(base).to_s }
    end
  else
    def self.glob_base(pattern, base)
      Dir.glob(pattern, base: base)
    end
  end
end
