task :default => :test

task :test do
  system %Q{
    rm -rf tmp/1234
    mkdir -p tmp/1234/working
    cp -R test-world/* tmp/1234/working
  }

  File.write 'tmp/1234/server.json', <<-EOS
{
  "id": "1234",
  "funpack": "minecraft-essentials",
  "port": 4032,
  "ram": {
    "min": 256,
    "max": 256
  },
  "settings" : {
    "blacklist": "atnan",
    "game_mode": 1,
    "new_player_can_build" : false,
    "ops": "whatupdave\\nchrislloyd",
    "seed": 123456789,
    "spawn_animals": "1",
    "spawn_monsters": "1",
    "whitelist": "whatupdave\\nchrislloyd"
  }
}
EOS

  run = File.expand_path 'bin/run'

  Dir.chdir('tmp/1234/working') do
    raise "error" unless system "#{run} ../server.json"
  end
end

desc "Update Bukkit server"
task :update_bukkit do
  system "curl -L http://cbukk.it/craftbukkit-beta.jar > template/craftbukkit.jar"
end