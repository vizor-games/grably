module Grably
  class TextJob # :nodoc:
    include Grably::Job

    call_as :text
    opt :content
    opt :filename

    def build
      out = job_dir(filename)
      File.open(out, 'w') do |f|
        dump(content, f)
      end
      out
    end

    def dump(content, io)
      io << content
    end
  end
end
