# frozen_string_literal: true

require 'rake_docker/version'
require 'rake_docker/output'
require 'rake_docker/container'
require 'rake_docker/exceptions'
require 'rake_docker/tasks'
require 'rake_docker/task_sets'
require 'rake_docker/authentication'

module RakeDocker
  def self.define_image_tasks(opts = {}, &)
    RakeDocker::TaskSets::Image.define(opts, &)
  end

  def self.define_container_tasks(opts = {}, &)
    RakeDocker::TaskSets::Container.define(opts, &)
  end
end
