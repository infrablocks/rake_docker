require 'rake_factory'

require_relative '../container'

module RakeDocker
  module Tasks
    class Provision < RakeFactory::Task
      default_name :provision
      default_description RakeFactory::DynamicValue.new { |t|
        "Provision #{t.container_name ? "#{t.container_name} " : ""}container."
      }

      parameter :container_name, :required => true
      parameter :image, :required => true
      parameter :ports
      parameter :environment

      parameter :ready_check

      parameter :reporter, default: Container::PrintingReporter.new

      action do |t|
        puts "Provisioning #{t.container_name} container"
        puts t.container_name
        puts t.image
        puts t.ports
        puts t.environment
        puts t.ready_check
        puts t.reporter
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
