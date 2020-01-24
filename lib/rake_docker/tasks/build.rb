require 'rake_factory'
require 'docker'

require_relative '../output'

module RakeDocker
  module Tasks
    class Build < RakeFactory::Task
      default_name :build
      default_description ->(t) { "Build #{t.image_name} image" }
      default_prerequisites ->(t) {
        t.prepare_task_name ?
            [Rake.application.current_scope
                .path_with_task_name(t.prepare_task_name)] :
            []
      }

      parameter :image_name, :required => true
      parameter :repository_name, :required => true

      parameter :credentials

      parameter :build_args

      parameter :work_directory, :required => true

      parameter :prepare_task_name, :default => :prepare

      action do |t|
        Docker.authenticate!(t.credentials) if t.credentials

        options = {t: t.repository_name}
        options = options.merge(
            buildargs: JSON.generate(t.build_args)) if t.build_args

        Docker::Image.build_from_dir(
            File.join(t.work_directory, t.image_name),
            options
        ) do |chunk|
          Output.print chunk
        end
      end
    end
  end
end
