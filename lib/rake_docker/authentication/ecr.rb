# frozen_string_literal: true

require 'aws-sdk-ecr'

module RakeDocker
  module Authentication
    class ECR
      def initialize(&block)
        @config =
          Struct.new(:region, :registry_id)
                .new(nil, nil)
        block.call(@config)

        @ecr_client = Aws::ECR::Client.new(region: @config.region)
      end

      def arity
        0
      end

      def call
        email = 'none'
        registry_id = resolve_registry_id
        token = get_authorization_token(registry_id)
        proxy_endpoint = extract_proxy_endpoint(token)
        username, password = extract_credentials(token)

        make_credentials_hash(email, password, username, proxy_endpoint)
      end

      private

      def make_credentials_hash(email, password, username, proxy_endpoint)
        {
          username: username,
          password: password,
          email: email,
          serveraddress: proxy_endpoint
        }
      end

      def resolve_registry_id
        if @config.registry_id.respond_to?(:call)
          @config.registry_id.call
        else
          @config.registry_id
        end
      end

      def get_authorization_token(registry_id)
        @ecr_client
          .get_authorization_token(registry_ids: [registry_id])
          .authorization_data[0]
      end

      def extract_proxy_endpoint(token)
        token.proxy_endpoint
      end

      def extract_credentials(token)
        Base64.decode64(token.authorization_token).split(':')
      end
    end
  end
end
