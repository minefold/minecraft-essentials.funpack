# encoding: UTF-8

class Processor
  def initialize(pid)
    @pid = pid
  end

  def event type, options = {}
    {
      ts: Time.now.utc.iso8601,
      event: type,
      pid: @pid
    }.merge(options)
  end

  def terminate!
    Process.kill :KILL, @pid
    puts JSON.dump event('error', msg: "terminating #{@pid}")
  end
end

class NormalLogProcessor < Processor
  def process_line(line)
    case line
    when /Done \(/
      event 'started'

    when /^<([\w;_~]+)> (.*)$/
      event 'chat', username: $1, msg: $2

    when 'Stopping server'
      event 'stopping'

    when /^(\w+).*logged in with entity id/
      event 'player_connected', username: $1

    when /^(\w+) lost connection: (.*)$/
      event 'player_disconnected', username: $1, reason: $2

    when /^(\w+) issued server command: \/(\w+) ([\w+ ]+)$/
      process_setting_changed $1, $2, $3

    when /FAILED TO BIND TO PORT!/
      event 'fatal_error', reason: 'port_bind_failed'
      Process.kill :TERM, @pid
      
    # ignore this particular error (LWC bug)
    when /^\[SEVERE\] java.lang.UnsatisfiedLinkError/
      event 'info', msg: line.strip

    when /^\[SEVERE\]/
      CrashLogProcessor

    when /^\[PartyCloud\] connected players:(.*)$/
      event 'players_list', usernames: $1.split(",")
    when /^connected players:(.*)$/
      event 'players_list', usernames: $1.split(",")

    else
      event 'info', msg: line.strip
    end
  end

  def settings_changed actor, key, value
    event 'settings_changed',
      actor: actor,
        key: key,
        value: value.to_s
  end

  def process_setting_changed actor, method, target
    case method
    when 'whitelist'
      op, target = target.split(' ')
      settings_changed actor, "whitelist_#{op}", target

    when 'ban'
      settings_changed actor, 'blacklist_add', target

    when 'pardon'
      settings_changed actor, 'blacklist_remove', target

    when 'op'
      settings_changed actor, 'ops_add', target

    when 'deop'
      settings_changed actor, 'ops_remove', target

    when 'defaultgamemode'
      settings_changed actor, 'game_mode', target

    when 'difficulty'
      modes = %w(peaceful easy normal hard)
      settings_changed actor, 'difficulty', modes.index(target.downcase)
    end
  end
end

class CrashLogProcessor < Processor
  def initialize(pid)
    super

    @lines = []

    Thread.new do
      # collect 5 seconds of log messages
      puts JSON.dump event('error', msg: 'collecting crash log')
      sleep 5

      # analyze
      reason = @lines.join("\n")
      if @lines.any?{|line| line =~ /OutOfMemoryError/}
        reason = 'out_of_memory'
      end

      puts JSON.dump(event('fatal_error', reason: reason))

      terminate!
    end
  end

  def process_line(line)
    @lines << line
    nil
  end
end

class LogProcessor
  def initialize(pid)
    @pid = pid
    @processor = NormalLogProcessor.new(pid)
  end

  def process_line(line)
    line = line.force_encoding('ISO-8859-1').
      gsub(/\u001b\[(m|\d+;\dm)?/, ''). # strip color sequences out
      gsub(/^[\d:]+\s/, ''). # strip time prefix
      gsub(/\[INFO\] /, '').strip # strip [INFO]

    result = @processor.process_line(line)
    if result.is_a?(Class)
      @processor = result.new(@pid)
      process_line(line)
    elsif !result.nil?
      puts JSON.dump(result)
    end

  rescue => e
    puts "exception #{e} #{e.backtrace}"
  end
end