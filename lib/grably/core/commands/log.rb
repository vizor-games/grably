module Grably # :nodoc:
  def log(msg)
    puts msg
    # flush stdout - we need that to have submodules displaying OK
    $stdout.flush
  end

  def err(msg)
    puts 'error: '.red.bright + msg
  end

  def warn(msg)
    puts 'warning: '.cyan.bright + msg.to_s.cyan
  end

  def trace(msg)
    puts msg if ENV['TRACE']
  end
end
