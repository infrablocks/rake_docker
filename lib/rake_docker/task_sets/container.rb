require 'rake_factory'
require 'docker'

require_relative '../tasks'
require_relative '../container'

module RakeDocker
  module TaskSets
    class Container < RakeFactory::TaskSet
      prepend RakeFactory::Namespaceable

      parameter :container_name, required: true
      parameter :image, required: true
      parameter :ports
      parameter :environment

      parameter :ready_check

      parameter :reporter,
          default: RakeDocker::Container::PrintingReporter.new

      parameter :provision_task_name, default: :provision
      parameter :destroy_task_name, default: :destroy

      task Tasks::Provision, name: RakeFactory::DynamicValue.new { |ts|
        ts.provision_task_name
      }
      task Tasks::Destroy, name: RakeFactory::DynamicValue.new { |ts|
        ts.destroy_task_name
      }
    end
  end
end
