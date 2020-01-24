require 'rake_factory'
require 'docker'

require_relative '../tasks'

module RakeDocker
  module TaskSets
    class All < RakeFactory::TaskSet
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

      parameter :clean_task_name, default: :clean
      parameter :prepare_task_name, default: :prepare
      parameter :build_task_name, default: :build
      parameter :tag_task_name, default: :tag
      parameter :push_task_name, default: :push

      task Tasks::Clean, name: ->(ts) { ts.clean_task_name }
      task Tasks::Prepare, name: ->(ts) { ts.prepare_task_name }
      task Tasks::Build, name: ->(ts) { ts.build_task_name }
      task Tasks::Tag, name: ->(ts) { ts.tag_task_name }
      task Tasks::Push, name: ->(ts) { ts.push_task_name }
    end
  end
end
