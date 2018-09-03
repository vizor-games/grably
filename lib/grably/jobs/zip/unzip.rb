module Grably # :nodoc:
  class UnzipJob # :nodoc:
    include Grably::Job

    srcs :files

    def setup(files)
      @files = files
    end

    def build
      log_msg 'Unpacking files'
      out = job_path('out')
      FileUtils.mkdir_p(out)

      files.each do |s|
        unpack(s, out, type: :zip)
      end

      out
    end
  end
end
