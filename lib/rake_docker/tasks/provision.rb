# frozen_string_literal: true

require 'rake_factory'

require_relative '../container'

module RakeDocker
  module Tasks
    class Provision < RakeFactory::Task
      default_name :provision
      default_description(RakeFactory::DynamicValue.new do |t|
        "Provision #{t.container_name ? "#{t.container_name} " : ''}container."
      end)

      parameter :container_name, required: true
      parameter :image, required: true
      parameter :ports
      parameter :environment
      parameter :command

      parameter :ready_check

      parameter :reporter, default: Container::PrintingReporter.new

      action do |t|
        puts "Provisioning #{t.container_name} container"
        provisioner = Container::Provisioner.new(
          t.container_name,
          t.image,
          ports: t.ports,
          environment: t.environment,
          command: t.command,
          ready?: t.ready_check,
          reporter: t.reporter
        )
        provisioner.execute
      end
    end
  end
end
