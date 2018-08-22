require 'grably/core/product'
require 'test/unit'

include Test::Unit
include Grably::Core
include Grably::Core::ProductExpand

class TestProductFilter < TestCase
  def test_filter_parse
    [
      [[nil, nil, '**/*'], '**/*'],
      [[nil, 'old_base', '**/*'], 'old_base:**/*'],
      [['new_base', nil, '**/*'], 'new_base::**/*'],
      [['new_base/foo', 'old_base/bar', 'files/*.{xml,yml,json}'], 'new_base/foo:old_base/bar:files/*.{xml,yml,json}']
    ].each do |expect, input|
      assert_equal(expect, ProductExpand.parse_string_filter(input))
    end
  end

  PRODUCTS = %w(xml/foo.xml bar/1.json bar2.json png/foo.json bar/one.png).map { |f| Product.new(f, f) }.freeze

  def test_string_filter_glob_match
    assert_empty(filter('**/*.jpeg', PRODUCTS))
    assert_equal(1, filter('**/*.xml', PRODUCTS).length)
    assert_equal(2, filter('!**/*.json', PRODUCTS).length)
    assert_equal(1, filter('png/*', PRODUCTS).length)
    assert_equal(1, filter('**/foo.json', PRODUCTS).length)
  end

  def test_remove_old_base
    assert_empty(filter('jpeg/**', PRODUCTS))
    assert_equal('foo.json', filter('png:**/*', PRODUCTS).first.dst)
  end

  def test_string_filter_match
    assert_equal(1, filter('json::**/foo.json', PRODUCTS).length)
  end

  def test_add_new_base
    assert_equal('json/png/foo.json', filter('json::**/foo.json', PRODUCTS).first.dst)
  end

  def filter(str, products)
    ProductExpand.generate_string_filter(str).call(products, nil)
  end
end
