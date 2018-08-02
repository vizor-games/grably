require 'grably/core'
require 'test/unit'

include Test::Unit
include Grably::Core
include Grably::Digest

class TestDigest < TestCase
  def test_digests_equal
    a = ProductDigest.new(Product.new('a.txt'), mtime: nil, size: nil, md5: nil)
    b = ProductDigest.new(Product.new('a.txt'), mtime: nil, size: nil, md5: nil)
    assert_equal(a, b)
  end

  def test_digest_differ_product
    a = ProductDigest.new(Product.new('a.txt'), mtime: nil, size: nil, md5: nil)
    b = ProductDigest.new(Product.new('b.txt'), mtime: nil, size: nil, md5: nil)
    assert_not_equal(a, b)
  end

  def test_digest_differ_mtime
    a = ProductDigest.new(Product.new('a.txt'), mtime: 1, size: nil, md5: nil)
    b = ProductDigest.new(Product.new('a.txt'), mtime: 3, size: nil, md5: nil)
    assert_not_equal(a, b)
  end

  def test_digest_differ_md5
    a = ProductDigest.new(Product.new('a.txt'), mtime: nil, size: nil, md5: 'beef')
    b = ProductDigest.new(Product.new('a.txt'), mtime: nil, size: nil, md5: 'deadbeef')
    assert_not_equal(a, b)
  end

  def test_diff_digests_missing
    missing, added, updated = Digest.diff_digests(*read_digest_sets(%w(a.txt b.txt c.txt d.txt), %w(a.txt b.txt c.txt)))

    assert_includes(missing, Product.new('d.txt'))
    assert_empty(added)
    assert_empty(updated)
  end

  def test_diff_digests_added
    missing, added, updated = Digest.diff_digests(*read_digest_sets(%w(a.txt b.txt c.txt), %w(a.txt b.txt c.txt d.txt)))

    assert_empty(missing)
    assert_include(added, Product.new('d.txt'))
    assert_empty(updated)
  end

  def test_diff_digests_updated
    old = create_digest_list(%w(a.txt b.txt))
    [
      ->(p) { ProductDigest.new(p.product, mtime: 1, size: nil, md5: nil) },
      ->(p) { ProductDigest.new(p.product, mtime: nil, size: 1, md5: nil) },
      ->(p) { ProductDigest.new(p.product, mtime: nil, size: nil, md5: 'foo') }
    ].each { |l| check_all_updated(l, old) }
  end

  def check_all_updated(transformer, old)
    new = old.map(&transformer)
    missing, added, updated = Digest.diff_digests(old, new)

    assert_empty(missing)
    assert_empty(added)
    assert_include(updated, Product.new('a.txt'))
    assert_include(updated, Product.new('b.txt'))
  end

  def create_digest_list(files)
    files.map { |f| ProductDigest.new(Product.new(f), mtime: nil, size: nil, md5: nil) }
  end

  def read_digest_sets(*args)
    args.map { |f| create_digest_list(f) }
  end
end
