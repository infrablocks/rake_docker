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
    end
  end
end
