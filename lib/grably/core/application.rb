require_relative 'app/enchancer'

module Rake
  # Rake application extensions
  class Application
    include Grably::Core::ApplicationEnchancer
  end
end
