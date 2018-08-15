module Grably # :nodoc:
  class << self
    # Current grably version identifier
    VERSION = [0, 0, 3].freeze

    # Returns grably version string
    # @return [String] version string
    def version
      VERSION.join('.')
    end
  end
end
