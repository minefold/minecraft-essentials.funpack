task :default => :test

task :test do
  system %Q{
    rm -rf tmp/world
    mkdir -p tmp/world
    cp -R test-bukkit-world/* tmp/world
  }

  File.write 'tmp/world/settings.json', <<-EOS
{
  "options" : {
    "new_player_can_build" : false,
    "name": "minecraft-vanilla",
    "minecraft_version": "HEAD",
    "ops": ["chrislloyd"],
    "whitelisted": ["whatupdave"],
    "banned": ["atnan"],
    "seed": 123456789,
    "spawn_animals": true,
    "spawn_monsters": true,
    "game_mode": 1
  }
}
  EOS

  raise "error" unless system "bin/prepare tmp/world tmp/world/settings.json"
  raise "error" unless system "bin/start tmp/world 4032 1024"
end