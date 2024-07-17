# frozen_string_literal: true

require 'spec_helper'
require 'aws-sdk-ecr'

describe RakeDocker::Authentication::ECR do
  it 'correctly fetches an authorization token for the supplied ' \
     'region and registry ID' do
    region = 'eu-west-2'
    registry_id = 'some-registry-id'

    username = 'super-secret-username'
    password = 'super-secret-token'

    client = stub_new_ecr_client(region)
    token = Base64.encode64("#{username}:#{password}")

    stub_successful_authorization_token_request(client, token)

    aws_ecr = described_class.new do |c|
      c.region = region
      c.registry_id = registry_id
    end

    aws_ecr.call

    expect(client)
      .to(have_received(:get_authorization_token)
            .with(registry_ids: [registry_id]))
  end

  it 'uses the supplied registry ID factory when supplied' do
    region = 'eu-west-2'
    registry_id = lambda do
      'some-computed-registry-id'
    end

    username = 'super-secret-username'
    password = 'super-secret-token'

    client = stub_new_ecr_client(region)
    token = Base64.encode64("#{username}:#{password}")

    stub_successful_authorization_token_request(client, token)

    aws_ecr = described_class.new do |c|
      c.region = region
      c.registry_id = registry_id
    end

    aws_ecr.call

    expect(client)
      .to(have_received(:get_authorization_token)
            .with(registry_ids: ['some-computed-registry-id']))
  end

  it 'returns username and password from the authorisation token' do
    region = 'eu-west-2'
    registry_id = 'some-registry-id'

    username = 'super-secret-username'
    password = 'super-secret-token'

    token = Base64.encode64("#{username}:#{password}")
    client = stub_new_ecr_client(region)

    stub_successful_authorization_token_request(client, token)

    aws_ecr = described_class.new do |c|
      c.region = region
      c.registry_id = registry_id
    end

    expect(aws_ecr.call)
      .to(include(
            username:,
            password:
          ))
  end

  it 'returns a serveraddress as the proxy_endpoint from the token' do
    region = 'eu-west-2'
    proxy_endpoint = 'dkr.ecr.eu-west-2.amazon.com'

    token = Base64.encode64('username:password')
    client = stub_new_ecr_client(region)

    stub_successful_authorization_token_request(client, token, proxy_endpoint)

    aws_ecr = described_class.new do |c|
      c.region = region
      c.registry_id = 'some-registry-id'
    end

    expect(aws_ecr.call)
      .to(include(serveraddress: proxy_endpoint))
  end

  it 'returns email of "none"' do
    region = 'eu-west-2'

    token = Base64.encode64('username:password')
    client = stub_new_ecr_client(region)

    stub_successful_authorization_token_request(client, token)

    aws_ecr = described_class.new do |c|
      c.region = region
      c.registry_id = 'some-registry-id'
    end

    expect(aws_ecr.call)
      .to(include(email: 'none'))
  end

  def authorization_token_response_double(token, proxy_endpoint = nil)
    proxy_endpoint ||= 'some-proxy-endpoint'
    Struct
      .new(:authorization_data)
      .new([Struct
              .new(:authorization_token, :proxy_endpoint)
              .new(token, proxy_endpoint)])
  end

  def ecr_client_double
    instance_double(Aws::ECR::Client)
  end

  def stub_new_ecr_client(region)
    client = ecr_client_double
    allow(Aws::ECR::Client)
      .to(receive(:new)
            .with(region:)
            .and_return(client))
    client
  end

  def stub_successful_authorization_token_request(
    client, token, proxy_endpoint = nil
  )
    allow(client)
      .to(receive(:get_authorization_token)
            .and_return(
              authorization_token_response_double(token, proxy_endpoint)
            ))
  end
end
