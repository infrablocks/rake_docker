# frozen_string_literal: true

require 'rake_factory'

module RakeDocker
  module Tasks
    class Clean < RakeFactory::Task
      default_name :clean
      default_description(RakeFactory::DynamicValue.new do |t|
        "Clean #{t.image_name} image directory"
      end)

      parameter :image_name, required: true
      parameter :work_directory, required: true

      action do |t|
        rm_rf File.join(t.work_directory, t.image_name)
      end
    end
  end
end
