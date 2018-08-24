require 'fileutils'
require 'zlib'
require 'rubygems/package'
require 'zip'

module Grably # :nodoc:
  # Pack products to archive
  # @param products [Array<Product>] list of products to pack
  # @param dst [String] archive name
  # @param type [Hash] archive options
  #   :type - archive type (one of :zip, :tar, :tar_gz). Archive type will be autodetected if absent.
  #   :compression_level - compression level for :zip and :tar_gz archive types
  def pack(products, dst, opts = {}) # rubocop:disable Metrics/MethodLength
    products = Product.expand(products)

    type = opts[:type]
    type = Compress.autodetect_archive_type(dst) if type.nil?

    case type
    when :zip
      Compress.pack_zip(products, dst, opts[:compression_level])
    when :tar
      File.open(dst, 'wb') do |f|
        Compress.pack_tar(products, f)
      end
    when :tar_gz
      Zlib::GzipWriter.open(dst, opts[:compression_level]) do |f|
        Compress.pack_tar(products, f)
      end
    else
      raise "unknown archive type: #{type}"
    end
  end

  # Unpack archive ot destination directory
  # @param src [String] archive path
  # @param dst_dir [String] destination directory
  # @param opts [Symbol] archive options
  #   :type = archive type (one of :zip, :tar, :tar_gz). Archive type will be autodetected if absent.
  def unpack(src, dst_dir, opts = {}) # rubocop:disable Metrics/MethodLength
    type = opts[:type]
    type = Compress.autodetect_archive_type(src) if type.nil?

    case type
    when :zip
      Compress.unpack_zip(src, dst_dir)
    when :tar
      File.open(src, 'rb') do |f|
        Compress.unpack_tar(f, dst_dir)
      end
    when :tar_gz
      Zlib::GzipReader.open(src) do |f|
        Compress.unpack_tar(f, dst_dir)
      end
    else
      raise "unknown archive type: #{type}"
    end
  end

  module Compress # :nodoc:
    module_function

    def pack_zip(products, dst, level = nil)
      Zip::OutputStream.open(dst) do |zip|
        products.each do |p|
          entry = Zip::Entry.new('', p.dst)
          entry.gather_fileinfo_from_srcpath(p.src)
          zip.put_next_entry(entry, nil, nil, Zip::Entry::DEFLATED, level)
          entry.get_input_stream { |is| Zip::IOExtras.copy_stream(zip, is) }
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
            # FileUtils.mkdir_p(dest, :mode => entry.header.mode, :verbose => false)
            FileUtils.mkdir_p(dest, verbose: false) unless File.exist?(dest)
          elsif entry.file? || (entry.header.typeflag == '' && !entry.full_name.end_with?('/'))
            unless File.exist?(dest)
              FileUtils.mkdir_p(File.dirname(dest))

              File.open(dest, 'wb') do |f|
                f.print(entry.read)
              end
              # FileUtils.chmod(entry.header.mode, dest, :verbose => false)
            end
          elsif entry.header.typeflag == '2' # Symlink!
            File.symlink(entry.header.linkname, dest)
          else
            raise "unknown tar entry: #{entry.full_name} type: #{entry.header.typeflag}"
          end

          dest = nil
        end
      end
    end

    def unpack_zip(src, dst_dir) # rubocop:disable Metrics/MethodLength
      File.open(src, 'rb') do |f|
        Zip::File.open_buffer(f,
                              restore_ownership: false,
                              restore_permissions: false,
                              restore_times: false) do |zip_file|
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
end
