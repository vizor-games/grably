require 'digest'

module Helpers
  # Compute sha1 hash of file with given path
  # @param file [String] path to file
  # @return [String] sha1 hexdigest
  def sha1(file)
    Digest::SHA1.hexdigest(IO.binread(file))
  end

  # Describes directory with array of file sha1 hashsums
  # @param dir [String] directory to describe
  # @return [Array<Hash>] computed file disgests
  def describe_dir(dir)
    files = Dir[File.join(dir, '**/*')].select { |f| File.file?(f) }
    files.map do |f|
      { 'file' => f.sub(dir + File::SEPARATOR, ''), 'sha1' => sha1(f) }
    end
  end
end
