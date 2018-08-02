require 'yaml'
require_relative 'text'

module Grably
  class YamlJob < TextJob # :nodoc:
    call_as :yaml

    def dump(content, io)
      YAML.dump(content, io)
    end
  end
end
