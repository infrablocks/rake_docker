require 'spec_helper'
require 'ostruct'

describe RakeDocker::Authentication::ECR do
  it 'correctly fetches an authorization token for the supplied ' +
         'region and registry ID' do
    region = 'eu-west-2'
    registry_id = 'some-registry-id'
    client = double('ECR client')

    username = 'super-secret-username'
    password = 'super-secret-token'

    token = Base64.encode64("#{username}:#{password}")
    context = OpenStruct.new(
        authorization_token: token,
        proxy_endpoint: 'some-proxy-endpoint')
    response = OpenStruct.new(
        authorization_data: [context])

    expect(Aws::ECR::Client)
        .to(receive(:new)
                .with(region: region)
                .and_return(client))
    expect(client)
        .to(receive(:get_authorization_token)
                .with(registry_ids: [registry_id])
                .and_return(response))

    aws_ecr = RakeDocker::Authentication::ECR.new do |c|
      c.region = region
      c.registry_id = registry_id
    end

    aws_ecr.call
  end

  it 'uses the supplied registry ID factory when supplied' do
    region = 'eu-west-2'
    registry_id = lambda do
      'some-computed-registry-id'
    end
    client = double('ECR client')

    username = 'super-secret-username'
    password = 'super-secret-token'

    token = Base64.encode64("#{username}:#{password}")
    context = OpenStruct.new(
        authorization_token: token,
        proxy_endpoint: 'some-proxy-endpoint')
    response = OpenStruct.new(
        authorization_data: [context])

    expect(Aws::ECR::Client)
        .to(receive(:new)
                .with(region: region)
                .and_return(client))
    expect(client)
        .to(receive(:get_authorization_token)
                .with(registry_ids: ['some-computed-registry-id'])
                .and_return(response))

    aws_ecr = RakeDocker::Authentication::ECR.new do |c|
      c.region = region
      c.registry_id = registry_id
    end

    aws_ecr.call
  end

  it 'returns username and password from the authorisation token' do
    region = 'eu-west-2'
    registry_id = 'some-registry-id'

    username = 'super-secret-username'
    password = 'super-secret-token'

    token = Base64.encode64("#{username}:#{password}")
    stub_aws_ecr_client(
        authorization_token: token)

    aws_ecr = RakeDocker::Authentication::ECR.new do |c|
      c.region = region
      c.registry_id = registry_id
    end

    expect(aws_ecr.call)
        .to(include(
                username: username,
                password: password))
  end

  it 'returns a serveraddress as the proxy_endpoint from the token' do
    proxy_endpoint = 'dkr.ecr.eu-west-2.amazon.com'
    stub_aws_ecr_client(
        proxy_endpoint: proxy_endpoint)

    aws_ecr = RakeDocker::Authentication::ECR.new do |c|
      c.region = 'eu-west-2'
      c.registry_id = 'some-registry-id'
    end

    expect(aws_ecr.call)
        .to(include(serveraddress: proxy_endpoint))
  end

  it 'returns email of "none"' do
    stub_aws_ecr_client

    aws_ecr = RakeDocker::Authentication::ECR.new do |c|
      c.region = 'eu-west-2'
      c.registry_id = 'some-registry-id'
    end

    expect(aws_ecr.call)
        .to(include(email: 'none'))
  end

  def stub_aws_ecr_client(opts = {})
    authorization_token = opts[:authorization_token] ||
        Base64.encode64('username:password')
    proxy_endpoint = opts[:proxy_endpoint] ||
        'some-endpoint'

    client = double('ECR client')
    allow(Aws::ECR::Client).to(receive(:new).and_return(client))

    context = OpenStruct.new(
        authorization_token: authorization_token,
        proxy_endpoint: proxy_endpoint)
    response = OpenStruct.new(authorization_data: [context])
    allow(client).to(receive(:get_authorization_token).and_return(response))
  end
end
