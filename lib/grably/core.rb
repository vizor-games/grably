require 'powerpack/string/strip_indent'

require_relative '../ext/class'
require_relative '../ext/dir'

require_relative 'core/essentials'
require_relative 'core/digest'
require_relative 'core/configuration'
require_relative 'core/product'
require_relative 'core/colors'

require_relative 'core/task'
require_relative 'core/application'
require_relative 'core/commands'
require_relative 'core/module'
require_relative 'core/dsl'

require_relative 'core/win_paths' if Grably.windows? && !Grably.jruby?
