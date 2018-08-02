require 'yaml'
require 'ostruct'
require 'jac'

module Grably
  module Core
    # Grably configuration module.
    # We use jac for configuration
    # @see https://github.com/vizor-games/jac
    module Configuration
      # Default configuration file names
      CONFIGURATION_FILES = %w(grably.yml grably.user.yml grably.override.yml).freeze

      class << self
        # Generates configuration object for given profile
        # and list of streams with YAML document
        # @param profile [Array] list of profile names to merge
        # @param streams [Array] list of YAML documents and their
        # names to read
        # @return [OpenStruct] instance which contains all resolved profile fields
        def read(profile, *streams)
          Jac::Configuration.read(profile, *streams)
        end

        # Read configuration from configuration files.
        # @praram [String or Array] profile which should be loaded
        # @param [String] dir base directory path for provided files may be nil
        # @return [OpenStruct] resolved profile values
        def load(profile, dir: nil)
          Jac::Configuration.load(profile, files: CONFIGURATION_FILES, dir: dir)
        end
      end
    end
  end
end
