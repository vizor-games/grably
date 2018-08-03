require lib('grably/core/digest')

module DigestHelpers
  include Grably::Digest
  def create_digest_list(files)
    files.map { |f| ProductDigest.new(Product.new(f), mtime: nil, size: nil, md5: nil) }
  end

  def read_digest_sets(*args)
    args.map { |f| create_digest_list(f) }
  end
end
