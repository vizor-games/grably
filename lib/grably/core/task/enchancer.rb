module Grably
  module Core
    # Wraps execute method, to print fancy info
    # about task and its execution.
    module TaskEnchancer
      class << self
        def included(other_class)
          other_class.class_eval do
            alias_method :old_execute, :execute

            def execute(*args)
              log_execute
              FileUtils.mkdir_p(task_dir)
              old_execute(*args)
              export(to_s, Grably.export_path) if Grably.export_tasks.include?(to_s)
            end
          end
        end
      end

      def export(name, export_path)
        puts "Exporting task #{name}"
        products = bucket
        # Evacuating files. When task is finished other task execution
        # may begin and all files that should be exported will be
        # spoiled.

        # Replace all ':' with '_'. When task name conatains ':' it
        # means that task declared inside namespace. On Windows we can't
        # create directory with ':' in name
        dir_name = name.tr(':', '_')
        dst = File.join(File.dirname(export_path), dir_name)
        Grably.exports << cp_smart(products, dst)
      end

      def task_dir
        File.join(WORKING_DIR, c.profile.join('-'), name)
      end

      def log_execute
        print "* #{self}".blue.bright
        if Grably.export?
          puts " (#{Dir.pwd}, #{c.profile.join('/').yellow})".white.bright
        else
          puts
        end
      end
    end
  end
end
