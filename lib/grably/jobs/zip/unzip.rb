module Grably # :nodoc:
  # TBD
  class UnzipJob
    include Grably::Job

    srcs :files

    def setup(files)
      @files = files
    end

    def build
      log 'Unpacking files'
      out = job_dir('out')
      FileUtils.mkdir_p(out)

      files.each do |s|
        ['unzip', '-d', out, s.src].run
      end

      out
    end
  end
end
