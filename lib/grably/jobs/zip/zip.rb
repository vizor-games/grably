module Grably # :nodoc:
  class ZipJob # :nodoc:
    include Grably::Job

    srcs :files
    opt :dst
    opt :meta

    def setup(srcs, dst, meta = {})
      @files = srcs
      @dst = dst
      @meta = meta
    end

    def build # rubocop:disable Metrics/AbcSize
      if files.empty?
        warn 'No files to zip'
        return []
      end

      log_msg "Zipping #{files.size} files into #{File.basename(dst)}"

      tmp_dst = job_path(File.basename(dst))
      pack(srcs, tmp_dst, compression_level: meta[:compression_level], type: :zip)
      Product.new(tmp_dst, dst, meta)
    end
  end
end
