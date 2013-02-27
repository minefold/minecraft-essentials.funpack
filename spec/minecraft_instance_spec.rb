require 'spec_helper'
require 'minecraft_instance'

describe MinecraftInstance do
  def self.paths(paths)
    before do
      stub = Find.stub(:find)
      paths.each do |path|
        stub.and_yield(path)
      end
    end
  end

  subject { MinecraftInstance.new('.') }

  context 'single player world' do
    paths %w(
      tmp/server/level.dat
      tmp/server/region/r.0.0.mca
    )
    its(:root) { should end_with 'tmp/server' }
    its(:level_paths) { should == ['tmp/server'] }
  end

  context 'server world' do
    paths %w(
      tmp/server/server.properties
      tmp/server/level/level.dat
    )
    its(:root) { should end_with 'tmp/server' }
    its(:level_paths) { should == ['tmp/server/level'] }
  end
end