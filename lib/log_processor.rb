# encoding: UTF-8

class LogProcessor
  def initialize(pid)
    @pid = pid
  end

  def process_line(line)
    line = line.force_encoding('ISO-8859-1').
      gsub(/\u001b\[(m|\d+;\dm)?/, ''). # strip color sequences out
      gsub(/[\d:]+\s\[[A-Z]+\]\s/, '').strip  # strip message prefix

    case line
    when /Done \(/
      event 'started'

    when /^<(\w+)> (.*)$/
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
      event 'fatal_error'
      Process.kill :TERM, @pid

    when /^\[PartyCloud\] connected players:(.*)$/
      event 'players_list', usernames: $1.split(",")

    else
      event 'info', msg: line.strip
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

  def event type, options = {}
    puts JSON.dump({
      ts: Time.now.utc.iso8601,
      event: type,
      pid: @pid
    }.merge(options))
  end
end