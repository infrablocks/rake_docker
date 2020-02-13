require 'rake_docker/version'
require 'rake_docker/output'
require 'rake_docker/container'
require 'rake_docker/exceptions'
require 'rake_docker/tasks'
require 'rake_docker/task_sets'
require 'rake_docker/authentication'

module RakeDocker
  def self.define_image_tasks(opts = {}, &block)
    RakeDocker::TaskSets::Image.define(opts, &block)
  end

  def self.define_container_tasks(opts = {}, &block)
    RakeDocker::TaskSets::Container.define(opts, &block)
  end
end
