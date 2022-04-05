# frozen_string_literal: true

require 'rake'
require 'pp'
require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'memfs'

module MemFs
  class Dir
    def self.children(dirname, _)
      entries(dirname) - ['.', '..']
    end
  end
end

# rubocop:disable RSpec/ContextWording
shared_context 'rake' do
  include ::Rake::DSL if defined?(::Rake::DSL)

  subject { self.class.top_level_description.constantize }

  let(:rake) { Rake::Application.new }

  before do
    Rake.application = rake
  end

  before do
    Rake::Task.clear
    MemFs.activate!
  end

  after do
    MemFs.deactivate!
  end
end
# rubocop:enable RSpec/ContextWording
