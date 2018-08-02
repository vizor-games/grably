module Grably
  module Job
    module InstanceMethods # rubocop:disable  Metrics/ModuleLength, Style/Documentation
      def run(task, working_dir, *args) # rubocop:disable  Metrics/MethodLength,  Metrics/AbcSize
        prepare(task, working_dir)
        initialize_state(*args) if stateful?

        if changed?
          clean unless incremental?
          log "  * [#{self.class.job_call_name}] building"
          result = @manifest.result = Grably::Core::Product.expand(build)
          @manifest.dump
        else
          log "  * [#{self.class.job_call_name}] uptodate"
          result = @manifest.result
        end

        result
      rescue StandardError => err
        # If any error occured this will force rebuild on next run
        @manifest.remove if @manifest
        raise(err)
      end

      # When job is changed it need to be reevaluated so build method will be
      # launched. If job remains unchanged previous result will be returned
      def changed?
        @changed
      end

      # Means that job has state which can be tracked between launches. If
      # job is stateless it always changed.
      def stateful?
        @stateful
      end

      # If job contains incremental srcs it is incremental. Incremental job
      # does not clean self state between launches. It should be managed by
      # user.
      def incremental?
        @job_args.any? { |_name, desc| desc.first == :isrc }
      end

      def job_dir(path = nil)
        path.nil? ? @job_dir : File.join(@job_dir, path)
      end

      def meta
        @manifest.meta
      end

      # Celans job state by removing all files from working directory
      def clean
        FileUtils.rm_rf(Dir[File.join(@job_dir, '*')])
      end

      private

      def prepare(task, working_dir)
        @job_dir = working_dir # initialize job dir
        @t = task
        @job_args = job_args_lookup
        # We need to track state only if job has arguments.
        @stateful = !@job_args.empty?
        # If job is stateful it is not changed by default. Only after stat will
        # be initialized we can say if it changed. If job has no state we should
        # always rebuild it. So changed != stateful
        @changed = !@stateful
        # In case if job has incremental sources we should keep deltas
        # somewhere. Deltas are kept in hash where they stored by field name.
        @deltas = {}
      end

      # Executes job state initialization by assigning values to instance
      # variables
      def initialize_state(*args)
        # Load previous state
        @manifest = Manifest.new(job_dir)
        _loaded = @manifest.load # try to load manifest

        if self.class.method_defined?(:setup)
          # This means that class has user defined method for initialization so
          # we should call this method for setup
          setup(*args)
        else
          # If no setup method defined we will use synthetic setup which assumes
          # that arguments is a Hash where keys is job argument names
          synthetic_setup(*args)
        end
        expand_job_arguments
      end

      def synthetic_setup(args)
        check_synthetic_arguments(args)
        args.each { |k, v| instance_variable_set("@#{k}", v) }
      end

      def check_synthetic_arguments(args)
        raise "Expected Hash got #{args.inspect}" unless args.is_a?(Hash)
        job_args = @job_args.keys
        extra = args.keys - job_args
        raise "Unknown arguments: #{extra.join(', ')}" unless extra.empty?
        missing = job_args - args.keys
        raise "Missing arguments #{missing.join(', ')}" unless missing.empty?
      end

      # Walks through all job arguments and does proper expand operation for its
      # value
      def expand_job_arguments
        @job_args.each do |name, desc|
          type, _extras = desc
          value = instance_variable_get("@#{name}")
          update_argument(name, type, value)
        end
      end

      def update_argument(name, type, value) # rubocop:disable Metrics/MethodLength
        case type
        when :src
          # src expects single product
          value = Product.expand(value, @t)
          raise(ArgumentError, "Expected only one product for #{name}") unless value.length == 1
          value = value.first
        when :srcs, :isrcs
          # src and isrcs expects multiple products
          value = Product.expand(value, @t)
        when :opt # rubocop:disable Lint/EmptyWhen
          # do nothing, we do not expand opt values. keeping them as is
        when nil
          raise(ArgumentError, "#{name} not defined")
        else
          raise(ArgumentError, "Unknown type #{type} for #{name}")
        end

        @manifest.update(name, type, value, ->(*a) { on_job_arg_set(*a) })
        instance_variable_set("@#{name}", value)
      end

      # rubocop:disable Metrics/ParameterLists
      def on_job_arg_set(name, type, old_digest, old_val, new_digest, new_val)
        if type == :isrcs
          # isrcs never impact changed state. We just need to gather infomration
          # about what actualy was changed
          @deltas[name] = Core::Digest.diff_digests(old_digest, new_digest)
        elsif old_val != new_val || old_digest != new_digest
          @changed = true
        end
      end
      # rubocop:enable Metrics/ParameterLists

      def job_args_lookup(klass = self.class, args = {})
        job_args_lookup(klass.superclass, args) if klass.superclass
        args.update(klass.job_args) if klass.included_modules.include?(Grably::Job)

        args
      end
    end
  end
end
