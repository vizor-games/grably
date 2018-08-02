require 'json'
require_relative 'text'

module Grably
  class JsonJob < TextJob # :nodoc:
    call_as :json

    def dump(content, io)
      JSON.dump(content, io)
    end
  end
end
