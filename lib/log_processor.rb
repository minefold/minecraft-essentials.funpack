# encoding: UTF-8

class Processor
  def initialize(pid)
    @pid = pid
  end

  def event type, options = {}
    {
      ts: Time.now.utc.iso8601,
      event: type,
    }.merge(options)
  end

  def terminate!
    Thread.new do
      puts JSON.dump event('error', msg: "terminating #{@pid}")
      sleep 5
      Process.kill :KILL, @pid
    end
  end
end

class NormalLogProcessor < Processor
  def process_line(line)
    case line
    when /Done \(/
      event 'started'

    when /^(\d+;\d+m)?<([\w;_~]+)> (.*)$/
      event 'chat', nick: $2, msg: $3

    when 'Stopping server'
      event 'stopping'

    when /^(\w+).*logged in with entity id/
      event 'player_connected', auth: 'mojang', uid: $1

    when /^(\w+) lost connection: (.*)$/
      event 'player_disconnected', auth: 'mojang', uid: $1, reason: $2

    when /^(\w+) issued server command: \/(\w+) ([\w+ ]+)$/
      process_setting_changed $1, $2, $3

    when /FAILED TO BIND TO PORT!/
      terminate!
      event 'fatal_error', reason: 'port_bind_failed'

    # out of memory
    when /^\[SEVERE\] java.lang.OutOfMemoryError/
      terminate!
      event 'fatal_error', reason: 'out_of_memory'

    when /^\[SEVERE\] The server has stopped responding!/
      terminate!
      event 'fatal_error', reason: 'The server has stopped responding!'

    when /^\[SEVERE\] The server has crashed!/
      terminate!
      event 'fatal_error', reason: 'The server has crashed!'

    when /^\[PartyCloud\] connected players:(.*)$/
      event 'players_list', auth: 'mojang', uids: $1.split(",")
    when /^connected players:(.*)$/
      event 'players_list', auth: 'mojang', uids: $1.split(",")

    else
      event 'info', msg: line.strip
    end
  end

  def process_setting_changed(actor, action, target)
    setting = {
      'op'     => { add: 'ops' },
      'deop'   => { remove: 'ops' },
      'ban'    => { add: 'blacklist' },
      'pardon' => { remove: 'blacklist' },
      'defaultgamemode' => { set: 'game_mode' },
    }[action]
    value = target

    if !setting
      setting = case action
      when 'whitelist'
        op, value = target.split(' ')
        { "#{op}" => 'whitelist' }

      when 'difficulty'
        field = @schema.fields.find{|f| f.name == :difficulty }
        value = field.values.find{|v| v['label'].downcase == target.downcase }
        { set: 'difficulty' }
      end
    end

    if setting
      event 'settings_changed', setting.merge(value: value)
    end
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