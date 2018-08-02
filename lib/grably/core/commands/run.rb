# Ruby array extensions
class Array
  # Run array content as shell command
  def run(&block)
    Grably.run(self, &block)
  end

  # Run array content as shell command and handle exception automaticly
  def run_safe
    Grably.run_safe(self)
  end

  # Run array content as shell command and print it output to STDOUT
  def run_log
    Grably.run_log(self)
  end
end

module Grably # :nodoc:
  # TODO: Rewimplement
  # rubocop:disable all
  class << self
    def run_log(cmd)
      run(cmd) { |l| log "  #{l}" }
    end

    def run(cmd, &block)
      env = {}

      cmd = [cmd] if cmd.is_a?(Hash)
      cmd = cmd.split(' ') unless cmd.is_a?(Array)
      cmd = cmd.flatten.compact

      cmd.map! do |c|
        if c.is_a?(String) && c.empty?
          c = nil
        elsif c.is_a?(Hash)
          env.merge!(c)
          c = nil
        end
        c = c.to_s unless c.nil?
        c
      end

      cmd = cmd.flatten.compact

      # Not all windows apps "slash tolerant"
      if windows?
        cmd[0] = cmd[0].tr('/', '\\') unless cmd.empty?
      end

      pwd = nil
      if env['__WORKING_DIR']
        pwd = Dir.pwd
        Dir.chdir(env.delete('__WORKING_DIR'))
      end

      r = []
      IO.popen([env, cmd, { err: %i(child out) }].flatten) do |o|
        o.sync = true
        o.each do |l|
          r << l
          yield(l) unless block.nil?
        end
      end

      Dir.chdir(pwd) if pwd

      raise 'error: '.red.bright + cmd.red + "\nfail log: #{r}".green unless $?.exitstatus.zero?

      r.join
    end

    def run_safe(cmd)
      begin
        run(cmd)
      rescue
        return false
      end

      true
    end
    # rubocop:enable all
  end
end
