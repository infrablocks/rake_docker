require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Clean < TaskLib
      parameter :name, :default => :clean

      parameter :image_name, :required => true
      parameter :work_directory, :required => true

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Clean #{image_name} image directory"
        task name do
          rm_rf File.join(work_directory, image_name)
        end
      end
    end
  end
end
