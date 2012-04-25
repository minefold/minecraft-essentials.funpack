# 00:00:00 [INFO] whatupdave: Opping minefold_guest
# 00:00:00 [INFO] whatupdave: De-opping minefold_guest
# 00:00:00 [INFO] whatupdave: Added minefold_guest to white-list
# 00:00:00 [INFO] whatupdave: Removed minefold_guest from white-list
# 00:00:00 [INFO] [PLAYER_COMMAND] whatupdave: /ban minefold_guest
# 00:00:00 [INFO] [PLAYER_COMMAND] whatupdave: /pardon minefold_guest

ROOT = File.join(File.dirname(__FILE__), '..')
TRANSFORM = File.expand_path "#{ROOT}/bin/transform"

def transform line
  `echo '00:00:00 [INFO] #{line}' | #{TRANSFORM}`.strip
end

describe 'transform' do
  {
    'whatupdave: Opping minefold_guest' => 'whatupdave issued server command: op minefold_guest',
    'whatupdave: De-opping minefold_guest' => 'whatupdave issued server command: deop minefold_guest',
    'whatupdave: Added minefold_guest to white-list' => 'whatupdave issued server command: whitelist add minefold_guest',
    'whatupdave: Removed minefold_guest from white-list' => 'whatupdave issued server command: whitelist remove minefold_guest',
    'whatupdave: /ban minefold_guest' => 'whatupdave issued server command: ban minefold_guest',
    'whatupdave: /pardon minefold_guest' => 'whatupdave issued server command: pardon minefold_guest',
  }.each do |input, output|
    context input do
      subject { transform input }
      it { should include output }
    end
  end
end