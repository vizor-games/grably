module Grably # :nodoc:
  # Shortcut to FileUtils.mkdir_p
  def mkdir(dirs)
    FileUtils.mkdir_p(dirs)
  end
end
