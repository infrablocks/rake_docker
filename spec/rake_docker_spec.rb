require 'spec_helper'

RSpec.describe RakeDocker do
  it 'has a version number' do
    expect(RakeDocker::VERSION).not_to be nil
  end
end
