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

namespace :update do
  desc "Update Bukkit server"
  task :bukkit do
    system "curl -L http://cbukk.it/craftbukkit-beta.jar > template/craftbukkit.jar"
  end

  task :worldguard do
    require 'tmpdir'
    template = File.expand_path('../template', __FILE__)

    tmp_dir = Dir.tmpdir
    `mkdir -p #{tmp_dir}`
    Dir.chdir(tmp_dir) do
      system %Q{
        curl -L http://dev.bukkit.org/media/files/645/438/worldguard-5.6.5.zip > wg.zip
        rm -rf wg
        mkdir -p wg
        cd wg
        unzip ../wg.zip
        cp WorldGuard.jar #{template}/plugins
      }
    end
  end

  task :worldedit do
    require 'tmpdir'
    template = File.expand_path('../template', __FILE__)

    tmp_dir = Dir.tmpdir
    `mkdir -p #{tmp_dir}`
    Dir.chdir(tmp_dir) do
      system %Q{
        curl -L http://dev.bukkit.org/media/files/644/439/worldedit-5.4.5.zip > we.zip
        rm -rf we
        mkdir -p we
        cd we
        unzip ../we.zip
        cp WorldEdit.jar #{template}/plugins
      }
    end
  end
end