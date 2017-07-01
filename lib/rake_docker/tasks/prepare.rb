require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Prepare < TaskLib
      parameter :name, :default => :prepare
      parameter :image, :required => true

      parameter :work_directory, :required => true

      parameter :copy_spec, :default => []
      parameter :create_spec, :default => []

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Prepare for build of #{image} image"
        task name do
          image_directory = File.join(work_directory, image)
          mkdir_p image_directory

          copy_spec.each do |entry|
            from = entry.is_a?(Hash) ? entry[:from] : entry
            to = entry.is_a?(Hash) ?
                File.join(image_directory, entry[:to]) :
                image_directory

            if File.directory?(from)
              mkdir_p to
              cp_r from, to
            else
              cp from, to
            end
          end

          create_spec.each do |entry|
            content = entry[:content]
            to = entry[:to]
            file = File.join(image_directory, to)

            mkdir_p(File.dirname(file))
            File.open(file, 'w') do |f|
              f.write(content)
            end
          end
        end
      end
    end
  end
end
