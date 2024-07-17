# frozen_string_literal: true

require 'rake_factory'
require 'docker'

module RakeDocker
  module Tasks
    class Tag < RakeFactory::Task
      default_name :tag
      default_description(RakeFactory::DynamicValue.new do |t|
        "Tag #{t.image_name} image for repository"
      end)

      parameter :image_name, required: true
      parameter :repository_name, required: true
      parameter :repository_url, required: true

      parameter :tags, required: true

      action do |t|
        images = Docker::Image.all(filter: t.repository_name)
        if images.empty?
          raise ImageNotFound,
                "No image found with name: '#{t.image_name}'"
        end

        image = images.first

        t.tags.each do |tag|
          image.tag(repo: t.repository_url,
                    tag:,
                    force: true)
        end
      end
    end
  end
end
