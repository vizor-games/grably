require 'fileutils'
require 'digest/sha1'

require_relative 'commands/digest'
require_relative 'commands/cp'
require_relative 'commands/log'
require_relative 'commands/run'
require_relative 'commands/serialize'

module Grably # :nodoc:
  # Make all methods as MODULE methods
  def self.method_added(m)
    module_function m
  end

  def relative_path(base, path)
    File.expand_path(path, base)
  end
end
