task :default => :test

task :test do
  # world_data = "test-world"
  world_data = "tmp/crash"
  system %Q{
    rm -rf tmp/1234
    mkdir -p tmp/1234/working
    cp -R #{world_data}/* tmp/1234/working
  }

  File.write 'tmp/1234/server.json', <<-EOS
{
  "id": "1234",
  "funpack": "minecraft-essentials",
  "port": 4032,
  "ram": {
    "min": 1024,
    "max": 1024
  },
  "settings" : {
    "blacklist": "atnan",
    "gamemode": 2,
    "ops": "whatupdave\\nchrislloyd",
    "seed": "s33d",
    "allow-nether": true,
    "allow-flight": false,
    "spawn-animals": true,
    "spawn-monsters": false,
    "spawn-npcs": false,
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
        curl -L http://build.sk89q.com/job/WorldGuard/lastBuild/artifact/target/worldguard-5.6.6-SNAPSHOT.zip > wg.zip
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
        curl -L http://build.sk89q.com/job/WorldEdit%20-%201.4.6%20Compatible/lastSuccessfulBuild/artifact/target/worldedit-5.4.6-TEMPFIX2.zip > we.zip
        rm -rf we
        mkdir -p we
        cd we
        unzip ../we.zip
        cp WorldEdit.jar #{template}/plugins
      }
    end
  end
end

task :publish do
  paths = %w(bin lib template Gemfile Gemfile.lock funpack.json)
  system %Q{
    archive-dir http://party-cloud-production.s3.amazonaws.com/funpacks/slugs/minecraft-essentials/stable.tar.lzo #{paths.join(' ')}
  }
end