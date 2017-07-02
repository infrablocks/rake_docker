require 'docker'
require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Build < TaskLib
      parameter :name, :default => :build

      parameter :image_name, :required => true
      parameter :repository_name, :required => true

      parameter :work_directory, :required => true

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Build #{image_name} image"
        task name do
          Docker::Image.build_from_dir(
              File.join(work_directory, image_name),
              {t: repository_name}) do |chunk|
            $stdout.puts chunk
          end
        end
      end
    end
  end
end
