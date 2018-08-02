require 'digest'
require 'set'

require_relative 'product'

module Grably
  # Set of utilities to digest products and stat product set changes
  module Digest
    # Describes product state. If two digests for same file differs assume file changed
    class ProductDigest
      attr_reader :mtime, :size, :md5, :product

      def initialize(product, mtime:, size:, md5:)
        @product = product
        @mtime = mtime
        @size = size
        @md5 = md5
      end

      def eql?(other)
        self == other
      end

      def ==(other)
        [
          product == other.product,
          mtime == other.mtime,
          size == other.size,
          md5 == other.md5
        ].all?
      end

      def hash
        md5.to_i
      end

      def self.[](*products)
        products.map { |p| of_product(p) }
      end

      def self.of_product(product)
        product = Product.new(product) if product.is_a?(String)
        raise 'Expected string or Product got ' + product.inspect unless product.is_a? Product
        src = product.src
        raise 'File does not exist' unless File.exist? src
        ProductDigest.new(
          product,
          mtime: File.mtime(src),
          size: File.size(src),
          md5: ::Digest::MD5.hexdigest(IO.binread(src))
        )
      end
    end

    # Given two lists of product digests
    # find missing, changed, and added products
    # @return [deleted, added, updated]
    def diff_digests(old_products, new_products)
      # create maps of product sets
      old_map, new_map = [old_products, new_products].map do |products|
        return [] unless products
        Hash[*products.flat_map { |d| [d.product, d] }]
      end

      build_diff(new_map, old_map)
    end

    def build_diff(new_map, old_map)
      old_keys = old_map.keys.to_set
      new_keys = new_map.keys.to_set

      missing = old_keys - new_keys
      added = new_keys - old_keys

      updated = (old_keys & new_keys).reject do |product|
        old_map[product] == new_map[product]
      end

      [missing, added, updated]
    end

    # Tells if two product digest lists are differ
    def differ?(old_products, new_products)
      !diff_digests(old_products, new_products).flatten.empty?
    end

    class << self
      def digest(*products)
        products.map { |product| ProductDigest.of_product(product) }
      end
    end
  end
end
