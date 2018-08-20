require 'tempfile'
require 'open3'

module Grably
  # Entry point to submodule task management
  class Server
    EXPORT_FILENAME = 'grably.export'.freeze
    def initialize
      @child_processes = {}
    end

    def schedule(call)
      ->(dir) { remote_result(call, File.expand_path(File.join(dir, EXPORT_FILENAME))) }
    end

    def remote_result(call, out_file)
      execute(call, out_file)
      load_obj(out_file)
    end

    # rubocop:disable all
    def execute(call, out_file, prefix: ' ')
      rakefile = call.path
      
      profile = *call.profile.map(&:to_s)

      if Grably.export_path
        data = [ rakefile, out_file, { 'target' => call.task, 'profile' => profile, 'params' => params } ]
        puts "remote_grably_request:#{JSON.generate(data)}"
        $stdout.flush
        $stdin.each do |l|
          raise "error in remote (slave) grably" unless l.strip == 'remote_grab_finished'
          break
        end
      else
        key = { rakefile: rakefile, profile: profile }
        
        process = @child_processes[key]
        
        unless process
          env = { 'config' => nil }
          cmd = [
            RbConfig.ruby,
            File.expand_path(File.join(__dir__, 'runner.rb')),
            '-f',
            File.basename(rakefile),
            "mp=#{profile.join(',')}"
          ]
          cmd << "--trace" if Rake.application.options.trace
          
          stdin, stdout, thread = Open3.popen2(*[env, cmd, { :err => [ :child, :out], :chdir => File.dirname(rakefile) }].flatten)
          stdout.sync = true
          stdin.sync = true
          
          process = { stdin: stdin, stdout: stdout, thread: thread }
          @child_processes[key] = process
        end
        
        process[:stdin].puts("build|#{out_file}|#{[call.task].flatten.join('|')}")
        
        ok = false
        process[:stdout].each do |l|
          ls = l.strip
          if ls == 'remote_grab_finished'
            ok = true
            break
          end
          
          if ls.start_with?('remote_grab_request:')
            data = JSON.parse(ls['remote_grab_request:'.size..-1])
            execute(data[0], data[1], "#{prefix}  ", { target: data[2]['target'], profile: data[2]['profile'], params: data[2]['params']})
            process[:stdin].puts('remote_grab_finished')
          else
            log "#{prefix}#{l}"
          end
        end
        
        raise 'error in remote grab' unless ok
      end
    end
    # rubocop:enable all
  end
end
