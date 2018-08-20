module Grably # :nodoc:
  def log_msg(msg)
    puts msg
    # flush stdout - we need that to have submodules displaying OK
    $stdout.flush
  end

  def err(msg)
    log_msg 'error: '.red.bright + msg
  end

  def warn(msg)
    log_msg 'warning: '.cyan.bright + msg.to_s.cyan
  end

  def trace(msg)
    log_msg msg if ENV['TRACE']
  end
end
