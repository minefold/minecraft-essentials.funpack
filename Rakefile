task :default => :test

task :test do
  system %Q{
    rm -rf tmp/world
    mkdir -p tmp/world
    cp -R test-world/* tmp/world
  }
  
  system "bin/prepare tmp/world"
  system "bin/start tmp/world 4032 1024"
end