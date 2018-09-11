require 'bundler/setup'

require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'

# Will use base grably module
require 'grably'

# build utils
require_relative './build/utils'
include Grably::Dev::Utils

RSpec::Core::RakeTask.new(:rspec)

# Code quality
# Linter
RuboCop::RakeTask.new(:lint) do |t|
  t.options = %w(-S -D)
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
