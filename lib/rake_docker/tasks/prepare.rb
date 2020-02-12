require 'rake_factory'

module RakeDocker
  module Tasks
    class Prepare < RakeFactory::Task
      default_name :prepare
      default_description RakeFactory::DynamicValue.new { |t|
        "Prepare for build of #{t.image_name} image"
      }

      parameter :image_name, :required => true

      parameter :work_directory, :required => true

      parameter :copy_spec, :default => []
      parameter :create_spec, :default => []

      action do |t|
        image_directory = File.join(t.work_directory, t.image_name)
        FileUtils.mkdir_p image_directory

        t.copy_spec.each do |entry|
          from = entry.is_a?(Hash) ? entry[:from] : entry
          to = entry.is_a?(Hash) ?
              File.join(image_directory, entry[:to]) :
              image_directory

          if File.directory?(from)
            FileUtils.mkdir_p to
            FileUtils.cp_r from, to
          else
            FileUtils.cp from, to
          end
        end

        t.create_spec.each do |entry|
          content = entry[:content]
          to = entry[:to]
          file = File.join(image_directory, to)

          FileUtils.mkdir_p(File.dirname(file))
          File.open(file, 'w') do |f|
            f.write(content)
          end
        end
      end
    end
  end
end
