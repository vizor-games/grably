module Grably # :nodoc:
  # Copy files or products to destination directory
  # @param products [Array<Product>] list of products to copy
  # @param dst_dir [String] destination directory to copy products
  # @param base_dir [String] if provided all products will be copied relative to
  #   this path inside destination
  # @param log [Boolean] if provided will log all actions to STDOUT. false by
  #   default
  # @return [Array<Product>] list of resulting products.
  def cp(products, dst_dir, base_dir: nil, log: false)
    products = Product.expand(products)
    dst_dir = File.expand_path(dst_dir)
    dst_dir = File.join(dst_dir, base_dir) if base_dir

    products.map { |product| copy_product(product, dst_dir, log: log) }
  end

  # Smart copy operates over product lists in the way like it directory
  # structures. All chaned products will be replaced and missing products
  # will be removed.
  # @param products [Array<Product>] list of products to copy. Any expand
  #   expression will work as expected.
  # @param dst_dir [String] target directory path.
  # @param log [Boolean] if set to true log all actions to STDOUT. false by
  #   default
  # @return [Array<Product>] list of resulting products
  def cp_smart(products, dst_dir, log: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # Ensure dst_dir is created
    FileUtils.mkdir_p(dst_dir) unless File.exist?(dst_dir)
    # Create Hash structures containing product.dst => product mappings
    update = ->(acc, elem) { acc.update(elem.dst => elem) }
    src_products = Product.expand(products).inject({}, &update)
    dst_products = Product.expand(dst_dir).inject({}, &update)

    # Looking for missing files
    remove_files = (dst_products.keys - src_products.keys).each do |dst_key|
      log_msg "Remove #{dst_key} (#{dst_products[dst_key].src}" if log
    end
    FileUtils.rm(remove_files.map { |k| dst_products[k].src })
    rm_empty_dirs(dst_dir)
    # Update rest
    src_products.map do |dst, product|
      dst_product = dst_products[dst]
      update_smart(product, dst_product, dst_dir, log: log)
    end
  end

  # Copy product to dst using FileUtils
  def cp_sys(src, dst, log: false)
    src = src.src if src.is_a?(Product)
    dst = dst.src if dst.is_a?(Product)
    log_msg "Copy #{File.basename(src)} to #{dst}" if log
    FileUtils.cp_r(src, dst)
  end

  private

  def rm_empty_dirs(dir)
    Dir[File.join(dir, '**/*')]
      .select { |p| File.directory?(p) }
      .select { |d| (Dir.entries(d) - %w(. ..)).empty? }
      .each { |d| Dir.rmdir(d) }
  end

  def copy_product(product, dst_dir, log: false)
    copy = product.map do |_src, dst, _meta|
      File.join(dst_dir, dst)
    end

    dir = File.dirname(copy.dst)
    FileUtils.mkdir_p(dir) unless File.exist?(dir)
    log_msg "Copy #{File.basename(product.src)} to #{copy.src}" if log
    FileUtils.cp(product.src, copy.src)

    copy
  end

  def update_smart(src_product, dst_product, dst_dir, log: false) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/LineLength
    if dst_product
      # Check if file changed. If so updating it
      # TODO: Should we or should not check hashsum
      if product_changed?(src_product, dst_product)
        log_msg "Update #{src_product.basename} to #{dst_product.src}" if log
        FileUtils.cp(src_product.src, dst_product.src)
      end
    else
      dst_product = src_product.map do |_src, dst, _meta|
        File.join(dst_dir, dst)
      end
      dir = File.dirname(dst_product.src)
      FileUtils.mkdir_p(dir) unless File.exist?(dir)
      log_msg "Copy #{src_product.basename} to #{dst_product.src}" if log
      FileUtils.cp(src_product.src, dst_product.src)
    end

    dst_product
  end

  def product_changed?(left, right)
    # TODO: Should we or should not check hashsums of files?
    digest(left) != digest(right) if File.mtime(left.src) != File.mtime(right.src)
  end
end
