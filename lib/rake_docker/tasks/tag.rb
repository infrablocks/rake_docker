require 'docker'
require 'ostruct'
require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Tag < TaskLib
      parameter :name, :default => :tag
      parameter :argument_names, :default => []

      parameter :image_name, :required => true
      parameter :repository_name, :required => true
      parameter :repository_url, :required => true

      parameter :tags, :required => true

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Tag #{image_name} image for repository"
        task name, argument_names do |_, args|
          params = OpenStruct.new(
              image_name: image_name,
              repository_name: repository_name
          )

          derived_repository_url = repository_url.respond_to?(:call) ?
              repository_url.call(*[args, params].slice(0, repository_url.arity)) :
              repository_url
          derived_tags = tags.respond_to?(:call) ?
              tags.call(*[args, params].slice(0, tags.arity)) :
              tags

          images = Docker::Image.all(filter: repository_name)
          if images.empty?
            raise RakeDocker::ImageNotFound,
                  "No image found with name: '#{image_name}'"
          end

          image = images.first

          derived_tags.each do |tag|
            image.tag(repo: derived_repository_url,
                      tag: tag,
                      force: true)
          end
        end
      end
    end
  end
end
