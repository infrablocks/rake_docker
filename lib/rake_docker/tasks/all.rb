require 'docker'
require_relative 'clean'
require_relative 'prepare'
require_relative 'build'
require_relative 'tag'
require_relative 'push'
require_relative '../tasklib'

module RakeDocker
  module Tasks
    class All < TaskLib
      parameter :containing_namespace

      parameter :image_name, :required => true
      parameter :repository_name, :required => true
      parameter :repository_url, :required => true

      parameter :work_directory, :required => true

      parameter :copy_spec, :default => []
      parameter :create_spec, :default => []

      parameter :tags, :required => true

      parameter :credentials

      parameter :clean_task_name, :default => :clean
      parameter :prepare_task_name, :default => :prepare
      parameter :build_task_name, :default => :build
      parameter :tag_task_name, :default => :tag
      parameter :push_task_name, :default => :push

      alias namespace= containing_namespace=

      def define
        if containing_namespace
          namespace containing_namespace do
            define_tasks
          end
        else
          define_tasks
        end
      end

      private

      def define_tasks
        Clean.new do |t|
          t.name = clean_task_name
          t.image_name = image_name
          t.work_directory = work_directory
        end
        Prepare.new do |t|
          t.name = prepare_task_name
          t.image_name = image_name
          t.work_directory = work_directory
          t.copy_spec = copy_spec
          t.create_spec = create_spec
        end
        Build.new  do |t|
          t.name = build_task_name
          t.image_name = image_name
          t.repository_name = repository_name
          t.work_directory = work_directory
          t.prepare_task = prepare_task_name
        end
        Tag.new do |t|
          t.name = tag_task_name
          t.image_name = image_name
          t.repository_name = repository_name
          t.repository_url = repository_url
          t.tags = tags
        end
        Push.new do |t|
          t.name = push_task_name
          t.image_name = image_name
          t.repository_url = repository_url
          t.tags = tags
          t.credentials = credentials
        end
      end
    end
  end
end
