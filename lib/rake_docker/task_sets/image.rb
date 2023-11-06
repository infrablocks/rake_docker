# frozen_string_literal: true

require 'rake_factory'
require 'docker'

require_relative '../tasks'

module RakeDocker
  module TaskSets
    class Image < RakeFactory::TaskSet
      prepend RakeFactory::Namespaceable

      parameter :image_name, required: true
      parameter :repository_name, required: true
      parameter :repository_url, required: true

      parameter :work_directory, required: true

      parameter :copy_spec, default: []
      parameter :create_spec, default: []

      parameter :argument_names, default: []

      parameter :tags, required: true

      parameter :credentials

      parameter :build_args
      parameter :platform

      parameter :clean_task_name, default: :clean
      parameter :prepare_task_name, default: :prepare
      parameter :build_task_name, default: :build
      parameter :tag_task_name, default: :tag
      parameter :push_task_name, default: :push
      parameter :publish_task_name, default: :publish

      task Tasks::Clean, name: RakeFactory::DynamicValue.new { |ts|
        ts.clean_task_name
      }
      task Tasks::Prepare, name: RakeFactory::DynamicValue.new { |ts|
        ts.prepare_task_name
      }
      task Tasks::Build, name: RakeFactory::DynamicValue.new { |ts|
        ts.build_task_name
      }
      task Tasks::Tag, name: RakeFactory::DynamicValue.new { |ts|
        ts.tag_task_name
      }
      task Tasks::Push, name: RakeFactory::DynamicValue.new { |ts|
        ts.push_task_name
      }
      task Tasks::Publish, name: RakeFactory::DynamicValue.new { |ts|
        ts.publish_task_name
      }
    end
  end
end
