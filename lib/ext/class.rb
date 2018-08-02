# Special grably specific class extensions
class Class
  def inherited(cl)
    # We need this, for code changes tracking.
    # For example, if job code changes, we need
    # rebuild it
    files = cl.const_defined?(files_const_name) ? cl.const_get(files_const_name) : []
    cl.const_set(files_const_name, files + [normalize_caller(caller)])
  end

  # Get all files included in current class
  def class_files
    const_get(files_const_name)
  end

  private

  CALLER_FILE_REGEX = /((\w:)?[^:]*):(.*)/

  # @return [String] containing constant name where files are stored
  def files_const_name
    'FILES'
  end

  def normalize_caller(caller)
    caller.first[CALLER_FILE_REGEX, 1].freeze
  end
end
