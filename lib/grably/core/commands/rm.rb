module Grably # :nodoc:
  # Shortcut to FileUtils.rm_rf
  def rm(srcs)
    FileUtils.rm_rf(srcs)
  end
end
