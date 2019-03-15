require 'aws-sdk-ecr'
require 'ostruct'

module RakeDocker
  module Authentication
    class ECR
      def initialize &block
        @config = OpenStruct.new(
            region: nil,
            registry_id: nil)
        block.call(@config)

        @ecr_client = Aws::ECR::Client.new(region: @config.region)
      end

      def arity
        0
      end

      def call
        registry_id = @config.registry_id.respond_to?(:call) ?
            @config.registry_id.call :
            @config.registry_id

        token_response = @ecr_client.get_authorization_token(
            registry_ids: [registry_id])
        token_data = token_response.authorization_data[0]
        proxy_endpoint = token_data.proxy_endpoint
        email = 'none'
        username, password =
            Base64.decode64(token_data.authorization_token).split(':')

        {
            username: username, password: password, email: email,
            serveraddress: proxy_endpoint
        }
      end
    end
  end
end