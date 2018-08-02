module Grably
  module Core
    module TaskExtensions
      # # Jobs
      # @see Grably::Core::Job
      module Jobs
        def method_missing(meth, *args, &block)
          job_class = find_job_class(meth.to_s)
          if job_class
            execute_job_with_args(args, job_class, meth)
          else
            super
          end
        end

        def execute_job_with_args(args, job_class, meth)
          working_dir = job_dir(task_dir, meth.to_s)
          FileUtils.mkdir_p(working_dir)
          job_class.new.run(self, working_dir, *args)
        end

        # Create working directory for instantiated job inside task directory
        # @param [String] base_dir task working directory
        # @param [String] job_name Grably::Job call name
        # @return [String] job working directory
        def job_dir(base_dir, job_name)
          # All this flow is working under assumption that all task jobs called
          # in same order. We store counter for each job in Task instance and
          # it updated throug all task live time. Each time task instance is
          # recreated we use frech (zero) counter
          counter = (jobs[job_name] || -1) + 1
          jobs[job_name] = counter
          name = [job_name, counter.to_s.rjust(3, '0')].join('-')
          File.join(base_dir, name)
        end

        def jobs
          @jobs ||= {}
        end

        def respond_to_missing?(meth, include_private = false)
          find_job_class(meth) || super
        end

        private

        def find_job_class(name)
          n = name.to_sym
          all_classes = Grably::Job.jobs.flat_map do |c|
            ObjectSpace.each_object(Class).select { |klass| klass <= c }
          end

          all_classes.find { |c| c.job_call_name == n }
        end
      end
    end
  end
end
