require_relative 'lib/grably/version'

Gem::Specification.new do |s|
  s.name        = 'grably'
  s.version     = Grably.version
  s.licenses    = ['Apache-2.0']
  s.summary     = 'Ruby library turning Rake into extreemly powerful build tool'
  s.authors     = ['Ilya Arkhanhelsky']
  s.email       = 'ilya.arkhanhelsky@vizor-games.com'
  s.files       = Dir['lib/**/*'] + %w(README.md LICENSE.txt)
  s.bindir      = 'exe'
  s.executables = Dir['exe/*'].map { |e| File.basename(e) }
  s.homepage    = 'https://rubygems.org/gems/grably'
  s.metadata    = {
    'source_code_uri' => 'https://github.com/vizor-games/grably'
  }

  s.add_runtime_dependency 'colorize', '~> 0.8.1'
  s.add_runtime_dependency 'jac', '~> 0.0.5'
  s.add_runtime_dependency 'powerpack', '~> 0.1.0'
  s.add_runtime_dependency 'rake', '~> 12.0'
  s.add_runtime_dependency 'rubyzip', '~> 1.2.1'
  s.add_runtime_dependency 'thor', '~> 0'
  s.add_runtime_dependency 'ffi'
end
