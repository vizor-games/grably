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

      # Key where binary configuration stored if any
      ENV_BINCONFIG_KEY = 'BIN_CONFIG'.freeze

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
          obj = Jac::Configuration.read(profile, *streams)
          obj.extend(self)
          obj
        end

        # Read configuration from configuration files.
        # @praram [String or Array] profile which should be loaded
        # @param [String] dir base directory path for provided files may be nil
        # @return [OpenStruct] resolved profile values
        def load(dir: nil, profile: [])
          profile += (ENV[ENV_PROFILE_KEY] || 'default').split(',')
          read(profile, *load_configuration_streams(dir))
        end

        def load_configuration_streams(dir)
          # Read all known files
          streams = CONFIGURATION_FILES
                    .map { |f| [dir ? File.join(dir, f) : f, f] }
                    .select { |path, _name| File.exist?(path) }
                    .map { |path, name| [IO.read(path), name] }

          streams << bin_config if bin_config?
          streams
        end

        # Reads binary configuration as YAML configuration stream so it could
        # be merged with other streams
        def bin_config
          data = hex_to_string ENV[ENV_BINCONFIG_KEY]
          # Data will be walid YAML string. Trick is ident its contend and
          # attach to ^top profile
          [
            "^top:\n" + data.split("\n").map { |x| '  ' + x }.join("\n"),
            ENV_BINCONFIG_KEY
          ]
        end

        # Converts hex string representation to plain string
        # @see https://en.wikipedia.org/wiki/Hexadecimal
        def hex_to_string(str)
          str.each_char.each_slice(2).inject('') do |acc, elem|
            acc + elem.map(&:chr).inject(&:+).hex.chr
          end
        end

        # Tells if binary configuration is provided
        def bin_config?
          ENV[ENV_BINCONFIG_KEY]
        end
      end
    end
  end
end
