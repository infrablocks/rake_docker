# frozen_string_literal: true

require 'rake_factory'
require 'docker'

module RakeDocker
  module Tasks
    class Push < RakeFactory::Task
      default_name :push
      default_description(RakeFactory::DynamicValue.new do |t|
        "Push #{t.image_name} image to repository"
      end)

      parameter :image_name, required: true
      parameter :repository_url, required: true

      parameter :credentials
      parameter :tags, required: true

      action do |t|
        Docker.authenticate!(t.credentials) if t.credentials

        images = Docker::Image.all(filter: t.repository_url)
        if images.empty?
          raise ImageNotFound,
                "No image found for repository: '#{t.repository_url}'"
        end

        image = images.first
        t.tags.each do |tag|
          image.push(nil, tag: tag) do |chunk|
            Output.print chunk
          end
        end
      end
    end
  end
end
