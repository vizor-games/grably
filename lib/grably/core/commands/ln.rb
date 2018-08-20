module Grably # :nodoc:
  # Essentialy FileUtils.ln under hood. But with some Grably flows kept in mind:
  #   * products argument can be any expandable expression
  #   * Needed directory structure will be created
  #   * If base_dir provided it will be appended to resulting products dst
  # This method returns list of all newly created products.
  # @param products [Object] any Product::expand expression
  # @param dir [String] destination dir
  # @param base_dir [String] base directory for all destination paths
  # @return [Array] of all created products.
  def ln(products, dir, base_dir: nil)
    targets = prelink(products, dir, base_dir)
    targets.each do |from, to|
      FileUtils.ln(File.expand_path(from.src), File.expand_path(to.src))
    end

    targets.map(&:last)
  end

  # Essentialy FileUtils.ln_s under hood. But with some Grably flows kept in
  # mind:
  #   * products argument can be any expandable expression
  #   * Needed directory structure will be created
  #   * If base_dir provided it will be appended to resulting products dst
  # This method returns list of all newly created products.
  # @param products [Object] any Product::expand expression
  # @param dir [String] destination dir
  # @param base_dir [String] base directory for all destination paths
  # @return [Array] of all created products.
  def ln_s(products, dir, base_dir: nil)
    targets = prelink(products, dir, base_dir)
    targets.each do |from, to|
      FileUtils.ln_s(File.expand_path(from.src), File.expand_path(to.src))
    end

    targets.map(&:last)
  end

  private

  # Execute prelink routines. We should prepare directory structure and create
  # new-old product paris.
  def prelink(products, dir, base_dir)
    products = Product.expand(products)
    dirs = products.map { |p| File.dirname(File.join(dir, p.dst)) }.uniq
    FileUtils.mkdir_p(dirs)

    products.map do |product|
      dst = product.dst
      dst = File.join(base_dir, dst) unless base_dir.nil?
      [product, product.map { |_s, d, m| [File.join(dir, d), dst, m.dup] }]
    end
  end
end
