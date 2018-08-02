module Grably
  module Dev
    # Module containing helper functions for base build Rakefile
    # Warning: it's not a part of Grably core module.
    module Utils
      def env_arg(name)
        ENV[name.to_s] || raise('No such argument in ENV: ' + name.to_s)
      end

      def run(cmd)
        print `#{cmd.join(' ')}`
      end
    end
  end
end
