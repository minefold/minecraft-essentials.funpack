task :default => :test

task :test do
  system %Q{
    rm -rf tmp/world
    mkdir -p tmp/world
    cp -R test-world/* tmp/world
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

desc "Update Bukkit server"
task :update_bukkit do
  system "curl -L http://dl.bukkit.org/downloads/craftbukkit/get/01371_1.3.1-R2.0/craftbukkit.jar > template/craftbukkit.jar"
end