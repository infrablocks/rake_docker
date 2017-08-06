require 'rake_docker/version'
require 'rake_docker/tasks'
require 'rake_docker/authentication'

module RakeDocker
  def self.define_image_tasks(&block)
    RakeDocker::Tasks::All.new(&block)
  end
end
