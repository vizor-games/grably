require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'rake/testtask'
require 'yard'

# Will use base grably module
require_relative 'lib/grably'

# build utils
require_relative './build/utils'
include Grably::Dev::Utils

RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = %w(-I lib/)
end

# Code quality
# Linter
RuboCop::RakeTask.new(:lint) do |t|
  t.options = %w(-S -D)
end

# Unit tests
Rake::TestTask.new do |t|
  t.libs << %w(test lib)
  t.test_files = FileList['test/**/test_*.rb']
end

desc 'Generate documentation'
YARD::Rake::YardocTask.new(:doc)

task :test => :rspec

desc 'Run lint and tests'
task :check => %i(test lint)

task :default => :check

namespace :deps do
  task :install do
    run %w(gem install bundler)
    run %w(bundle)
  end
end
