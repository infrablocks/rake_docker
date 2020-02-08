require 'rake_factory'

module RakeDocker
  module Tasks
    class Provision < RakeFactory::Task
      default_name :provision
      default_description ->(t) {
        "Start #{t.container_name ? "#{t.container_name} " : ""}container."
      }

      parameter :container_name, :required => true
      parameter :image, :required => true
      parameter :ports
      parameter :environment

      parameter :ready_check

      parameter :reporter, default: Container::NullReporter.new

      action do |t|
        puts "Starting #{t.container_name ? "#{t.container_name} " : ""} " +
            "container"
        provisioner = Container::Provisioner.new(
            t.container_name,
            t.image,
            ports: t.ports,
            environment: t.environment,
            ready?: t.ready_check,
            reporter: t.reporter)
        provisioner.execute
      end
    end
  end
end
