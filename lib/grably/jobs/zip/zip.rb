module Grably # :nodoc:
  # TBD
  class ZipJob
    include Grably::Job

    OPTIONS = {
      compression_level: ->(value) { "-r#{value}" }
    }.freeze

    srcs :files
    opt :dst
    opt :meta

    def setup(srcs, dst, meta = {})
      @files = srcs
      @dst = dst
      @meta = meta
    end

    def build
      if files.empty?
        warn 'No files to zip'
        return []
      end

      log "Zipping #{files.size} files into #{File.basename(dst)}"

      src_dir = job_dir('src')
      ln(files, src_dir)
      zip(src_dir)
    end

    def zip(dir)
      Dir.chdir(dir) do
        ['zip', cflags, File.join('..', File.basename(dst)), '.'].run
      end
      Product.new(job_dir(File.basename(dst)), dst, meta)
    end

    def cflags
      OPTIONS
        .select { |k, _v| meta.key?(k) }
        .map { |k, _v| OPTIONS[k].call(meta[k]) }
    end
  end
end
