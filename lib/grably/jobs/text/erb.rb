require 'erb'
require_relative 'text'

module Grably
  class ErbJob < TextJob # :nodoc:
    class ErbBinder < OpenStruct # :nodoc:
      def eval(template)
        ERB.new(template).result(binding)
      end
    end

    call_as :erb

    src :template
    opt :content
    opt :filename
    opt :context

    def setup(template:, context:)
      @template = template
      @content = read(template)
      @filename = basename(template, '.erb')
      @context = context
    end

    def dump(content, io)
      io << ErbBinder.new(context).eval(content)
    end

    def read(src)
      src = src.src if src.is_a?(Product)
      IO.read(src)
    end

    def basename(file, ext = nil)
      file = file.src if file.is_a? Product
      File.basename(file, ext)
    end
  end
end
