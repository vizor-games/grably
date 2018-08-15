require 'yaml'
require 'ostruct'
require 'jac'

require_relative 'configuration/pretty_print'

module Grably
  module Core
    # Grably configuration module.
    # We use jac for configuration
    # @see https://github.com/vizor-games/jac
    module Configuration
      # Key where required profile is placed.
      # To load grably with profile `foo,bar` one need to
      # run `rake mp=foo,bar task1, task2, ... taskN`
      ENV_PROFILE_KEY = 'mp'.freeze

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
        def load(dir: nil, profile: [])
          profile += (ENV[ENV_PROFILE_KEY] || 'default').split(',')
          puts 'Loding profile ' + profile.join('/')
          obj = Jac::Configuration.load(profile, files: CONFIGURATION_FILES, dir: dir)
          obj.extend(self)
          obj
        end
      end
    end
  end
end
