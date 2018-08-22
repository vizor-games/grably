require 'grably/core'
require 'test/unit'

include Test::Unit
include Grably::Core

class TestProduct < TestCase
  def test_equals
    product = Product.new('foo.txt', 'foo.txt', foo: 'bar')
    product2 = Product.new('foo.txt', 'foo.txt', bar: 'bar')

    assert_equal(product, product2)
    assert_not_equal(product.meta, product2.meta)
  end

  def test_grab_meta
    product = Product.new('foo.txt', 'foo.txt', foo: 'xml', bar: 'json', qoo: 42)
    foo, bar, qoo = product[:foo, :bar, :qoo]
    assert_equal(foo, 'xml')
    assert_equal(bar, 'json')
    assert_equal(qoo, 42)

    assert_equal(product[:foo], 'xml')
  end

  def test_meta_update
    original = Product.new('foo.txt')
    updated = original.update(foo: 42)
    assert_equal(original, updated) # Because meta is not taken in count
    assert_not_same(original, updated) # But we create new object
    assert_equal({ foo: 42 }, updated.meta)
  end

  def test_include_list
    list = *Product.new('a.txt')
    assert_includes(list, Product.new('a.txt'))
  end
end
