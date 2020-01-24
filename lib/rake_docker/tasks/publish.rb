require 'rake_factory'

module RakeDocker
  module Tasks
    class Publish < RakeFactory::Task
      default_name :publish
      default_description ->(t) { "Publish #{t.image_name} image" }

      parameter :image_name

      parameter :clean_task_name, default: :clean
      parameter :build_task_name, default: :build
      parameter :tag_task_name, default: :tag
      parameter :push_task_name, default: :push

      action do |t, args|
        Rake::Task[t.scope.path_with_task_name(t.clean_task_name)].invoke(*args)
        Rake::Task[t.scope.path_with_task_name(t.build_task_name)].invoke(*args)
        Rake::Task[t.scope.path_with_task_name(t.tag_task_name)].invoke(*args)
        Rake::Task[t.scope.path_with_task_name(t.push_task_name)].invoke(*args)
      end
    end
  end
end
