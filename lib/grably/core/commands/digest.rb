require 'digest/sha2'

module Grably # :nodoc:
  def digest(src, buff_len: 4096)
    src = src.src if src.is_a?(Product)
    sha = ::Digest::SHA2.new
    File.open(src, 'rb') do |f|
      sha << f.read(buff_len) until f.eof?
    end
    sha.hexdigest
  end
end
