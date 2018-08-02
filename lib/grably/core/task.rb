require 'rake/task'

require_relative 'task/bucket'
require_relative 'task/jobs'
require_relative 'task/expand'
require_relative 'task/enchancer'

module Grably
  # All working files are stored under .grably directory.
  WORKING_DIR = '.grably'.freeze

  module Core
    # We use Grably::Core::Task as alias to Rake::Task
    Task = Rake::Task

    # Here we will put extension methods for task
    module TaskExtensions
      include Grably::Core::TaskExtensions::Bucket
      include Grably::Core::TaskExtensions::Jobs
      include Grably::Core::TaskExtensions::Expand
    end
  end
end

module Rake
  class Task # :nodoc:
    include Grably::Core::TaskExtensions
    include Grably::Core::TaskEnchancer
  end
end
