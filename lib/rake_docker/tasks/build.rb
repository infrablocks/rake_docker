require 'docker'
require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Build < TaskLib
      parameter :name, :default => :build
      parameter :argument_names, :default => []

      parameter :image_name, :required => true
      parameter :repository_name, :required => true

      parameter :credentials

      parameter :work_directory, :required => true

      parameter :prepare_task, :default => :prepare

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        prerequisites = prepare_task ?
            [scoped_task_name(prepare_task)] :
            []

        desc "Build #{image_name} image"
        task name, argument_names => prerequisites do |_, args|
          params = OpenStruct.new(
              image_name: image_name,
              repository_name: repository_name,
              credentials: credentials,
              work_directory: work_directory
          )

          derived_credentials = credentials.respond_to?(:call) ?
              credentials.call(*[args, params].slice(0, credentials.arity)) :
              credentials

          Docker.authenticate!(derived_credentials) if derived_credentials

          Docker::Image.build_from_dir(
              File.join(work_directory, image_name),
              {t: repository_name}) do |chunk|
            $stdout.puts chunk
          end
        end
      end

      private

      def scoped_task_name(task_name)
        Rake.application.current_scope.path_with_task_name(task_name)
      end
    end
  end
end
