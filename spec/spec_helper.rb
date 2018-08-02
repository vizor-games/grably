require 'rspec'
require 'tmpdir'
require 'powerpack/string'
require 'simplecov'

SimpleCov.start

def lib(path)
  File.join(__dir__, '..', 'lib', path)
end

module Rake
  class Application
    def top_level
      # fake top_level
    end
  end
end

require_relative lib('grably/core')
include Grably
