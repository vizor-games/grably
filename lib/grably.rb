# Always require rake
require 'rake'

# Grably main module.
# TBD
module Grably
  module Core # :nodoc:
    # forward declaration
  end
  include Grably::Core

  GRABLY_BANNER = '' \
                  '__       ______           __    __      __|' \
                  '\ \     / ____/________ _/ /_  / /_  __/ /|' \
                  ' \ \   / / __/ ___/ __ `/ __ \/ / / / / / |' \
                  ' / /  / /_/ / /  / /_/ / /_/ / / /_/ /_/  |' \
                  '/_/   \____/_/   \__,_/_.___/_/\__, (_)   |' \
                  '                              /____/      |'.tr('|', "\n")

  def config
    Grably.config
  end

  # Handy aliases for config methods
  alias c config
  alias cfg config
  alias conf config

  class << self
    attr_reader :config
    def init
      @config = Grably::Core::Configuration.load
    end

    def server
      @server ||= Grably::Server.new
    end

    attr_writer :export_path

    def export_path
      @export_path || ENV['EXPORT']
    end

    def export_tasks
      @export_tasks ||= (ENV['EXPORT_TASKS'] || '').split(',')
    end

    def export_tasks=(task_names)
      @export_tasks = task_names.dup.freeze
    end

    def export?
      # Ensure boolean value
      !!export_path # rubocop:disable Style/DoubleNegation
    end

    def exports
      @exports ||= []
    end

    def [](path = Dir.pwd, task = :default)
      Grably::Module.reference(path, task)
    end
  end
end

require_relative 'grably/core'
require_relative 'grably/job'
require_relative 'grably/jobs'
require_relative 'grably/server'

# Init grably
Grably.init
Rake::TaskManager.record_task_metadata = true

puts Grably::GRABLY_BANNER.green.bright unless Grably.export?
include Grably
include Grably::DSL

require_relative 'grably/tasks'
