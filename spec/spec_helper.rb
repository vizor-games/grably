require 'rspec'
require 'tmpdir'
require 'powerpack/string'
require 'simplecov'

require_relative 'helpers'

SimpleCov.start

module Rake
  class Application
    def top_level
      # fake top_level
    end
  end
end

# require_relative lib('grably/core')
include Grably

RSpec.configure do |c|
  c.include Helpers
end
