require 'rake'
require 'pp'
require 'active_support'
require 'active_support/core_ext/string/inflections.rb'
require 'memfs'

module MemFs
  class Dir
    def self.children(dirname, _)
      self.entries(dirname) - [".", ".."]
    end
  end
end

shared_context :rake do
  include ::Rake::DSL if defined?(::Rake::DSL)

  let(:rake) { Rake::Application.new }
  subject { self.class.top_level_description.constantize }

  before do
    Rake.application = rake
  end

  before(:each) do
    Rake::Task.clear
    MemFs.activate!
  end

  after(:each) do
    MemFs.deactivate!
  end
end