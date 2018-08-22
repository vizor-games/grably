require 'fileutils'
require 'zlib'
require 'rubygems/package'
require 'zip'

module Grably # :nodoc:
  # Pack products to archive
  # @param products [Array<Product>] list of products to pack
  # @param dst [String] archive name
  # @param type [Symbol] archive type (one of :zip, :tar, :tar_gz).
  #   Archive type will be autodetected in case of nil
  def pack(products, dst, type = nil) # rubocop:disable Metrics/MethodLength
    products = Product.expand(products)

    type = autodetect_archive_type(dst) if type.nil?

    if type == :zip
      pack_zip(products, dst)
    elsif type == :tar
      File.open(dst, 'wb') do |f|
        pack_tar(products, f)
      end
    elsif type == :tar_gz
      Zlib::GzipWriter.open(dst) do |f|
        pack_tar(products, f)
      end
    else
      raise "unknown archive type: #{type}"
    end
  end

  # Unpack archive ot destination directory
  # @param src [String] archive path
  # @param dst_dir [String] destination directory
  # @param type [Symbol] archive type (one of :zip, :tar, :tar_gz).
  #   Archive type will be autodetected in case of nil
  def unpack(src, dst_dir, type = nil) # rubocop:disable Metrics/MethodLength
    type = autodetect_archive_type(src) if type.nil?

    if type == :zip
      unpack_zip(src, dst_dir)
    elsif type == :tar
      File.open(src, 'rb') do |f|
        unpack_tar(f, dst_dir)
      end
    elsif type == :tar_gz
      Zlib::GzipReader.open(src) do |f|
        unpack_tar(f, dst_dir)
      end
    else
      raise "unknown archive type: #{type}"
    end
  end

  private

  def pack_zip(products, dst)
    Zip::File.open(dst, Zip::File::CREATE) do |zip_file|
      products.each do |p|
        zip_file.get_output_stream(p.dst) do |f|
          f.write(File.open(p.src, 'rb').read)
        end
      end
    end
  end

  def pack_tar(products, stream)
    Gem::Package::TarWriter.new(stream) do |tar|
      products.each do |p|
        s = File.stat(p.src)
        tar.add_file_simple(p.dst, s.mode, s.size) do |io|
          io.write(File.open(p.src, 'rb').read)
        end
      end
    end
  end

  TAR_LONGLINK = '././@LongLink'.freeze

  def unpack_tar(stream, dst_dir) # rubocop:disable all
    Gem::Package::TarReader.new(stream) do |tar|
      dest = nil
      tar.each do |entry|
        if entry.full_name == TAR_LONGLINK
          dest = File.join(dst_dir, entry.read.strip)
          next
        end

        dest ||= File.join(dst_dir, entry.full_name)

        if entry.directory? || (entry.header.typeflag == '' && entry.full_name.end_with?('/'))
          raise "file already exist: #{dest}" if File.exist?(dest)
          # FileUtils.mkdir_p(dest, :mode => entry.header.mode, :verbose => false)
          FileUtils.mkdir_p(dest, verbose: false)
        elsif entry.file? || (entry.header.typeflag == '' && !entry.full_name.end_with?('/'))
          raise "file already exist: #{dest}" if File.exist?(dest)

          FileUtils.mkdir_p(File.dirname(dest))

          File.open(dest, 'wb') do |f|
            f.print(entry.read)
          end
          # FileUtils.chmod(entry.header.mode, dest, :verbose => false)
        elsif entry.header.typeflag == '2' # Symlink!
          File.symlink(entry.header.linkname, dest)
        else
          raise "unknown tar entry: #{entry.full_name} type: #{entry.header.typeflag}"
        end

        dest = nil
      end
    end
  end

  def unpack_zip(src, dst_dir)
    File.open(src, 'rb') do |f|
      Zip::File.open_buffer(f, restore_ownership: false, restore_permissions: false, restore_times: false) do |zip_file|
        zip_file.each do |entry|
          dst_file = File.join(dst_dir, entry.name)
          FileUtils.mkdir_p(File.dirname(dst_file))
          entry.extract(dst_file)
        end
      end
    end
  end

  def autodetect_archive_type(src)
    return :zip if src.end_with?('.zip', '.jar')
    return :tar if src.end_with?('.tar')
    return :tar_gz if src.end_with?('.tar.gz', '.tgz')
    raise "error detecting archive type for: #{src}"
  end
end
