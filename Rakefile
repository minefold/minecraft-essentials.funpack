task :default => :test

task :test do
  system %Q{
    rm -rf tmp/world
    mkdir -p tmp/world
    cp -R test-world/* tmp/world
  }

  File.write 'tmp/world/settings.json', <<-EOS
{
  "new_player_can_build" : true
}
  EOS

  system "bin/prepare tmp/world tmp/world/settings.json"
  system "bin/start tmp/world 4032 1024"
end