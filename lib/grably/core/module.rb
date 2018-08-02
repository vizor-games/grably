require 'rake/application'
module Grably
  # Methods for working with submodules
  module Module
    # List of file names we can load as submodule entry
    DEFAULT_FILES = Rake::Application::DEFAULT_RAKEFILES

    # Reference to external module task call
    class ModuleCall
      attr_reader :path, :profile, :task
      # Initializes module reference with load path and profile
      # @param [String] path absolute path to referencing module
      def initialize(path, task, profile = c.profile)
        @path = path
        @task = task
        @profile = profile
      end

      # Updates profile settings in module ref
      # @param [*String] profile profile names
      def with_profile(*profile)
        @profile = profile
        self
      end

      def pretty_print
        profiles = [*profile].flatten.join(', ')
        "Call Grably[#{path} / #{profiles}] #{task.to_s.white.bright}"
      end
    end

    class << self
      # Get submodule object
      # @param [String] path relative path to sumbodule
      # @return [Grably::Module::ModuleCall] addresed submodule
      def reference(path, task)
        base_path = File.expand_path(File.join(Dir.pwd, path))
        raise "#{path} does not exist" unless File.exist?(path)
        path = if File.directory?(base_path)
                 ensure_module_dir(base_path)
               else
                 ensure_filename(base_path)
               end
        ModuleCall.new(path, task)
      end

      # Ensures that provided path points to one of allowed to load files
      def ensure_filename(path)
        basename = File.basename(path)
        return path if DEFAULT_FILES.include?(basename)

        exp = DEFAULT_FILES.join(', ')
        raise "Wrong file name #{basename} expected one of #{exp}"
      end

      def ensure_module_dir(path)
        base_path = Dir["#{path}/*"]
                    .find { |f| DEFAULT_FILES.include?(File.basename(f)) }
        raise "Can't find any file to load in #{path}" unless base_path
        base_path
      end
    end
  end
end
