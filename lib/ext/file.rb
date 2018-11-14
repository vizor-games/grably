class File # :nodoc:
  class << self
    # Allows to join path with missing parts. Missing values simply dropped
    # from concatenation
    def join_safe(*values)
      File.join(*values.compact)
    end
  end
end
