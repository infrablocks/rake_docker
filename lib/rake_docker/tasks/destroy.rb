# frozen_string_literal: true

require 'rake_factory'

require_relative '../container'

module RakeDocker
  module Tasks
    class Destroy < RakeFactory::Task
      default_name :destroy
      default_description(RakeFactory::DynamicValue.new do |t|
        "Destroy #{t.container_name ? "#{t.container_name} " : ''}container."
      end)

      parameter :container_name, required: true

      parameter :reporter, default: Container::PrintingReporter.new

      action do |t|
        puts "Destroying #{t.container_name} container"
        destroyer = Container::Destroyer.new(
          t.container_name,
          reporter: t.reporter
        )
        destroyer.execute
      end
    end
  end
end
