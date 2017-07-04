require 'docker'
require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Tag < TaskLib
      parameter :name, :default => :tag

      parameter :image_name, :required => true
      parameter :repository_name, :required => true
      parameter :repository_url, :required => true

      parameter :tag
      parameter :tag_as_latest, :default => false

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Tag #{image_name} image for repository"
        task name do
          params = OpenStruct.new({
              image_name: image_name,
              repository_name: repository_name
          })

          derived_repository_url = repository_url.respond_to?(:call) ?
              repository_url.call(*[params].slice(0, repository_url.arity)) :
              repository_url
          derived_tag = tag.respond_to?(:call) ?
              tag.call(*[params].slice(0, tag.arity)) :
              tag

          images = Docker::Image.all(filter: repository_name)
          if images.empty?
            raise RakeDocker::ImageNotFound,
                  "No image found with name: '#{image_name}'"
          end

          image = images.first
          image.tag(repo: derived_repository_url,
                    tag: derived_tag,
                    force: true) if derived_tag
          image.tag(repo: derived_repository_url,
                    tag: 'latest',
                    force: true) if tag_as_latest
        end
      end
    end
  end
end
