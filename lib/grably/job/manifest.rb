require 'ostruct'
require 'fileutils'

module Grably
  module Job
    # Manifest file with job data. Manifest keeps information about previous run
    # including passed arguments and output file digests
    class Manifest
      # Manifest file location relative to jobdir
      MANIFEST = '.manifest'.freeze

      attr_reader :manifest_file

      def initialize(job_dir)
        @job_dir = job_dir
        @data = OpenStruct.new(src: {}, srcs: {}, opt: {}, result: nil, meta: {})
        @manifest_file = File.join(job_dir, MANIFEST)
      end

      def update(name, type, value, update_hook) # rubocop:disable Metrics/MethodLength,  Metrics/AbcSize
        case type
        when :src
          old_value, old_digest = @data.src[name]
          new_digest = Grably::Digest.digest(value).first
        when :srcs
          old_value, old_digest = @data.srcs[name]
          new_digest = Grably::Digest.digest(*value)
        when :opt
          old_value, _old_digest = @data.opt[name]
          old_digest = nil
          new_digest = nil
        else
          raise ArgumentError, 'Invalid type: ' + type
        end

        @data.send(type)[name] = [value, new_digest]
        update_hook.call(name, type, old_value, old_digest, value, new_digest)
        [old_value, old_digest]
      end

      def result=(products)
        digests = Grably::Digest.digest(*products)
        @data.result = [products, digests]
      end

      def meta
        @data.meta
      end

      def result
        @data.result.first
      end

      def load
        @data = load_obj(manifest_file) if File.exist?(manifest_file)
      end

      def dump
        save_obj(manifest_file, @data)
      end

      def remove
        FileUtils.rm_f(manifest_file)
      end
    end
  end
end
