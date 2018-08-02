module Grably
  module Job
    module ClassMethods # :nodoc:
      # Mark instance variable as source product container. When field contains
      # source product job will track its state between launches. If product
      # was changed since last run job is considered as changed and will be
      # rebuild. This method also generates attribute_reader for given variable.
      # @param name [Symbol] attribute name
      # @param extras [Hash] extra arguments. Now unsued.
      def src(name, extras = {})
        class_exec do
          attr_reader name
          register_job_argument(name, :src, extras)
        end
      end

      # Mark instance variable as multiple source product container. When field
      # contains multiple src products job will track each product state
      # between launches. If any of source products was changed since last run
      # job is considered as changed and will be rebuild. This method also
      # generates attribute_reader for given variable.
      # @param name [Symbol] attribute name
      # @param extras [Hash] extra arguments. Now unsued.
      def srcs(name, extras = {})
        class_exec do
          attr_reader name
          register_job_argument(name, :srcs, extras)
        end
      end

      # Mark instance variable as incremental sources container. When field
      # contains incremental sources it does not impact on job state. But job
      # setup will generate state delta between two launches. This allows to
      # decide if job should be rebuild completely or only changed files should
      # be rebuild. This method generates two syntatic instance methods:
      # * standart attribute accessor which contains current products
      # * ! attribute_accessor (i.e. foo! ) which will return delta array in
      #   following format: [ modifications, additions, deletions ]
      # @param name [Symbol] attribute name
      # @param extras [Hash] extra arguments. Now unsued.
      def srcs!(name, extras = {})
        class_exec do
          attr_reader name
          register_job_argument(name, :isrcs, extras)
          eval("def #{name}!; @deltas[:#{name}]; end") # rubocop:disable Security/Eval
        end
      end

      # Mark instance variable as option container. When field contains option
      # job will track its value between launches. If value was changed since
      # last run job is considered as changed and will be rebuild. This method
      # also generates attribute_reader for given variable.
      # @param name [Symbol] attribute name
      # @param extras [Hash] extra arguments. Now unsued.
      def opt(name, extras = {})
        class_exec do
          attr_reader name
          register_job_argument(name, :opt, extras)
        end
      end

      def register_job_argument(name, type, extras)
        job_args[name] = [type, extras]
      end

      def job_args
        @job_args ||= {}
      end

      def job_call_name
        return unless name # TODO: in runtime some anonymous sublcass instances
        # can be created find out when and why
        # job_call_name by user with call_as method. Yet it is not required
        # if job_call_name empty we'll try to sytetize job name
        @job_call_name ||= synthesize_job_name
      end

      def call_as(name)
        @job_call_name = name
      end

      # Try to syntetize job name from class name
      # * Strip all parent modules names
      # * Cut off Job postfix from class name if any
      # * convert class name to snake case
      def synthesize_job_name
        klass_name = name.scan(/[^:]+/).last
        klass_name = klass_name[/(.+)Job/, 1] || klass_name
        klass_name.scan(/[A-Z][a-z]+/).map(&:downcase).join('_').to_sym
      end
    end
  end
end
