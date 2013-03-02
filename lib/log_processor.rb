# encoding: UTF-8

class LogProcessor
  def initialize(pid, schema)
    @pid = pid
    @mode = :normal
    @schema = schema
  end

  def process_line(line)
    line = line.force_encoding('ISO-8859-1').
      gsub(/\u001b\[(m|\d+;\dm)?/, ''). # strip color sequences out
      gsub(/^[\d:]+\s/, ''). # strip time prefix
      gsub(/\[INFO\] /, '').strip # strip [INFO]

    result = case @mode
    when :normal
      process_normal_line(line)
    when :stats
      process_stats_line(line)
    end

  rescue => e
    puts "exception #{e} #{e.backtrace}"
  end

  def process_normal_line(color)
    line = color.gsub('33;22m', '')
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

    when /^\[SEVERE\] This crash report has been saved to/
      terminate!
      event 'fatal_error', reason: 'The server has stopped responding!'

    when /^\[SEVERE\] The server has crashed!/
      terminate!
      event 'fatal_error', reason: 'The server has crashed!'

    when /^\[PartyCloud\] connected players:(.*)$/
      event 'players_list', auth: 'mojang', uids: $1.split(",")
    when /^connected players:(.*)$/
      event 'players_list', auth: 'mojang', uids: $1.split(",")

    when /Uptime: (\d+)/
      process_stats_line(line)

    when /^[\w ]+ "\w+": [\d,]+ chunks, [\d,]+ entities\.$/
      # ignore chunk stats lines

    else
      event 'info', msg: line.strip
    end
  end

  # Uptime: 4 minutes 22 seconds
  # Current TPS = 20.0
  # Maximum memory: 633 MB.
  # Allocated memory: 633 MB.
  # Free memory: 398 MB.
  # World "level": 256 chunks, 315 entities.
  # Nether "level_nether": 0 chunks, 0 entities.
  # The End "level_the_end": 0 chunks, 0 entities.

  def process_stats_line(line)
    line.gsub!('33;22m', '')

    @stats ||= {}
    @mode = :stats

    case line
    when /^Uptime: (.*)/
      @stats['uptime'] = human_time_in_minutes($1)
    when /^Current TPS = (.*)/
      @stats['tps'] = $1.to_f
    when /^Maximum memory: (.*) MB/
      @stats['ram_max'] = $1.to_i
    when /^Allocated memory: (.*) MB/
      @stats['ram_alloc'] = $1.to_i
    when /^Free memory: (.*) MB/
      @stats['ram_free'] = $1.to_i
    else
      @mode = :normal
      event 'stats', @stats

      process_normal_line(line)
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

  def time_part(time, part)
    if match = time.match(/(\d+) #{part}/)
      match[1].to_i
    end
  end

  # 17 hours 68 minutes 74 seconds
  def human_time_in_minutes(human)
    hours = time_part(human, 'hours') || 0
    mins = time_part(human, 'minutes') || 0

    mins + (hours * 60)
  end

  def event(type, options = {})
    puts JSON.dump({
      ts: Time.now.utc.iso8601,
      event: type,
    }.merge(options))
  end

  def terminate!
    Thread.new do
      puts JSON.dump event('error', msg: "terminating #{@pid}")
      sleep 5
      Process.kill :KILL, @pid
    end
  end
end