#!/usr/bin/ruby

require 'rake'

module Rake
  class Application # :nodoc:
    def run_tasks(tasks)
      standard_exception_handling do
        collect_command_line_tasks(tasks)
        top_level
      end
    end
  end
end

rake = Rake.application
rake.init
ENV['EXPORT'] = '1'
rake.load_rakefile

$stdin.each do |l|
  cmds = l.strip.split('|')
  cmd = cmds.shift
  exit(0) if cmd == 'exit'
  exit(1) unless cmd == 'build'
  Grably.export_path = cmds.shift
  Grably.export_tasks = cmds
  rake.run_tasks(cmds)
  puts 'remote_grab_finished'
  $stdout.flush
end
