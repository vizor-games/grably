require 'json'
module Grably
  module Utils
    # Profile structure printer
    module PrettyPrinter
      def print(hash, buffer, ident)
        hash.each do |key, value|
          v = value[:value]
          r = value[:raw_value] # raw value for interpolated strings
          print_top_level(key, v, r, buffer, ident)
        end
      end

      private

      def print_top_level(key, value, raw, buffer, ident)
        buffer << "#{ident}#{key}: "
        if value.is_a?(Hash) || value.is_a?(Array)
          buffer << "\n"
          print_value(value, buffer, ident + '  ')
        else
          buffer << value.to_s
          buffer << "(raw: #{raw})" if raw
          buffer << "\n"
        end
      end

      def print_value(v, buffer, ident, skip = false)
        if v.is_a? Array
          print_array(v, buffer, ident, skip)
        elsif v.is_a? Hash
          print_hash(v, buffer, ident, skip)
        else
          print_string(v, buffer, ident, skip)
        end
      end

      def print_string(v, buffer, _, _ = false)
        buffer << v
        buffer << "\n"
      end

      def print_hash(v, buffer, ident, skip_first = false)
        i = skip_first ? '' : ident
        v.each do |k, e|
          buffer << "#{i}#{k}: "
          print_value(e, buffer, ident + '  ', !e.is_a?(Array))
          i = ident
        end
      end

      def print_array(v, buffer, ident, skip_first = false)
        i = skip_first ? '' : ident
        v.each do |e|
          buffer << "#{i}- "
          buffer << "\n" if e.is_a?(Array)
          print_value(e, buffer, ident + '  ', !e.is_a?(Array))
          i = ident
        end
      end
    end
  end
end
