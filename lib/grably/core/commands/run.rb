require 'open3'
require 'shellwords'

# Ruby array extensions
class Array
  # Run array content as shell command
  def run(opts = {}, &block)
    Grably.run(self, opts, &block)
  end

  # Run array content as shell command and handle exception automaticly
  def run_safe(opts = {})
    Grably.run_safe(self, opts)
  end

  # Run array content as shell command and print it output to STDOUT
  def run_log(opts = {})
    Grably.run_log(self, opts)
  end
end

module Grably # :nodoc:
  class << self
    def run_log(cmd, opts)
      run(cmd, opts) { |l| log_msg "  #{l}" }
    end

    def run_safe(cmd, opts)
      return run(cmd, opts)
    rescue StandardError => _err
      return nil
    end

    # General abstraction to run commands in open3 way. Intended use is
    # run commands and get result. If command fails - method raises exception.
    # STDERR is merged to STDOUT by default. If block given then each line from
    # STDOUT will be passed to block.
    # @param cmd [Array] list structure of Strings or Hashes. List allowed to be
    #   nested yet it will be flatten. Any provied Hash will contribute to
    #   launching process ENV. All String objects expected to be either command
    #   or it's arguments.
    # @param opts [Hash] pure Open3 options Hash. Most useful example is
    #   `chdir:` used to change working directory of child process.
    # @block could be provided to process contens of STDOUT and STDERR
    # @returns String lines from STDOUT and STDERR
    def run(cmd, opts = {}, &_block) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      env, cmd = prepare_cmd(cmd)
      # Store last command. env and cmd flipped, because usualy we more
      # interested in command instead of environment
      Grably.last_command = [cmd, env]
      lines = ''
      status = Open3.popen2e(env, *cmd, opts) do |_stdin, stdout_and_stderr, thr|
        stdout_and_stderr.sync = true
        stdout_and_stderr.each do |l|
          lines += l
          yield(l) if block_given?
        end
        lines.chomp!
        thr.value
      end

      return lines if status.exitstatus.zero?
      # Store error and exitstatus for later use. It useful when building
      # CI piplines and one can use error message.
      Grably.last_command = [cmd, status.exitstatus, lines]
      raise 'error: '.red.bright + Shellwords.shelljoin(cmd).red + "\nfail log: #{lines}".green
    end

    attr_reader :last_command

    def last_command=(cmd)
      @last_command = cmd.dup.freeze
    end

    private

    def prepare_cmd(cmd)
      # Normalize cmd array. We expecting array of Strings or Hashes
      cmd = [cmd] if cmd.is_a?(Hash)
      cmd = cmd.split(' ') if cmd.is_a?(String)
      cmd = cmd.flatten.compact

      # Split array in two parts:
      #  - Hash elements responsible for populating env
      #  - String elemnts responsible for command body. Nothing else
      #    expected here.
      env, cmd = cmd.partition { |x| x.is_a?(Hash) }

      # Transform all values to strings
      cmd.map!(&:to_s)

      # TODO: Should we or should not fix splashes for windows commands. And how
      # it should be implemented. Legacy code was like
      #  # Not all windows apps "slash tolerant"
      #  if windows?
      #  cmd[0] = cmd[0].tr('/', '\\') unless cmd.empty?
      #  end
      # However it does not seem like general solution.

      # Merging env and return tuple-like structure
      [env.inject({}) { |a, e| a.update(e) }, cmd]
    end
  end
end
