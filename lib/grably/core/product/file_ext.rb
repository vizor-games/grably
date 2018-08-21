module Grably
  # Adds useful file extensions checking methods to Product instances.
  module ProductFileExtensions
    def respond_to_missing?(meth, *args, &block)
      super || meth.to_s.end_with?('?')
    end

    def method_missing(meth, *args, &_block)
      m = meth.to_s
      return check_file_extension(m[0..-2]) if m.end_with?('?') && args.empty?
      super
    end

    private

    def check_file_extension(ext)
      src.end_with?('.' + ext)
    end
  end
end
