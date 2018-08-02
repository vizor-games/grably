module Grably # :nodoc:
  def load_obj(filename)
    return nil unless File.exist? filename
    File.open(filename) do |f|
      Marshal.load(f) # rubocop:disable Security/MarshalLoad
    end
  rescue StandardError => x
    raise(x, "Can't deserialize #{filename}")
  end

  def save_obj(filename, obj)
    dir = File.dirname(filename)
    FileUtils.mkdir(dir) unless File.exist?(dir)
    File.open(filename, 'w') { |f| Marshal.dump(obj, f) }
  end
end
