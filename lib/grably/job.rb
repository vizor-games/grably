require_relative 'core/product'
require_relative 'core/digest'

require_relative 'job/exceptions'
require_relative 'job/manifest'
require_relative 'job/class'
require_relative 'job/instance'

module Grably
  # TBD
  module Job
    # includes "Job::InstanceMethods" and extends "Job::ClassMethods"
    # using the Job.included callback.
    # @!parse include Job::InstanceMethods
    # @!parse extend Job::ClassMethods
    class << self
      def included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        jobs << receiver
      end

      def jobs
        @jobs ||= []
      end
    end
  end
end
