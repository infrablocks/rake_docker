require 'docker'
require 'ostruct'
require_relative '../tasklib'

module RakeDocker
  module Tasks
    class Push < TaskLib
      parameter :name, :default => :push

      parameter :image_name, :required => true
      parameter :repository_url, :required => true

      parameter :credentials
      parameter :tags, :required => true

      def process_arguments(args)
        self.name = args[0] if args[0]
      end

      def define
        desc "Push #{image_name} image to repository"
        task name do
          params = OpenStruct.new(
              image_name: image_name,
              repository_url: repository_url,
              credentials: credentials,
              tag: tags
          )

          derived_repository_url = repository_url.respond_to?(:call) ?
              repository_url.call(*[params].slice(0, repository_url.arity)) :
              repository_url
          derived_credentials = credentials.respond_to?(:call) ?
              credentials.call(*[params].slice(0, credentials.arity)) :
              credentials
          derived_tags = tags.respond_to?(:call) ?
              tags.call(*[params].slice(0, tags.arity)) :
              tags

          Docker.authenticate!(derived_credentials) if derived_credentials

          images = Docker::Image.all(filter: derived_repository_url)
          if images.empty?
            raise RakeDocker::ImageNotFound,
                  "No image found for repository: '#{derived_repository_url}'"
          end

          image = images.first
          derived_tags.each do |tag|
            image.push(nil, tag: tag) do |chunk|
              $stdout.puts chunk
            end
          end
        end
      end
    end
  end
end
