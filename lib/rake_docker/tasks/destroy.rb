require 'rake_factory'

require_relative '../container'

module RakeDocker
  module Tasks
    class Destroy < RakeFactory::Task
      default_name :destroy
      default_description ->(t) {
        "Destroy #{t.container_name ? "#{t.container_name} " : ""}container."
      }

      parameter :container_name, :required => true

      parameter :reporter, default: Container::NullReporter.new

      action do |t|
        puts "Destroying #{t.container_name ? "#{t.container_name} " : ""} " +
            "container"
        destroyer = Container::Destroyer.new(
            t.container_name,
            reporter: t.reporter)
        destroyer.execute
      end
    end
  end
end
