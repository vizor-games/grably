require 'thor'
require 'rake'
require 'yaml'

require_relative 'version'
require_relative 'core/configuration'
module Grably
  # Grably CLI tool. Gives access to basic grably commands. Allowing to fetch
  # basic infromation about build configuration, grably version and much more
  # in the future.
  class GrablyCLI < Thor
    map %w(--version -v) => :version
    map %w(x) => :exec

    option :profile, type: :string, default: 'default', aliases: :'-p', banner: '<profile>'
    desc 'exec ...TASKS', 'Execute build tasks'
    def exec(*tasks)
      Rake.application.run(tasks + ["mp=#{options[:profile]}"])
    end

    desc 'tasks', 'Print defined task descriptions (unimplemented)'
    option :all, type: :boolean, aliases: '-a'
    def tasks
      args = %w(-T)
      args << '-A' if options[:all]
      Rake.application.run(args)
    end

    option :profile, type: :string, aliases: :'-p', banner: '<profile>'
    desc 'config', 'Pretty print current configuration'
    def config
      app = Rake.application
      ENV[Grably::ENV_PROFILE_KEY] = options[:profile]
      app.load_rakefile
      Grably.config.pretty_print
    end

    desc 'version', 'Show version.'
    def version
      puts "grably v. #{Grably.version}"
      exit 1
    end
  end
end

Grably::GrablyCLI.start(ARGV)
