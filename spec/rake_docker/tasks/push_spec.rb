require 'spec_helper'

describe RakeDocker::Tasks::Push do
  include_context :rake

  before(:each) do
    stub_print
    stub_docker_authenticate
    stub_docker_image_search
  end

  it 'adds a push task in the namespace in which it is created' do
    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
          tags: ['latest'])
    end

    expect(Rake::Task.task_defined?('image:push')).to(be(true))
  end

  it 'gives the push task a description' do
    subject.define(
        image_name: 'nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest'])

    expect(Rake::Task["push"].full_comment)
        .to(eq('Push nginx image to repository'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.define(
          name: :push_to_ecr,
          image_name: 'nginx',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
          tags: ['latest'])
    end

    expect(Rake::Task.task_defined?('image:push_to_ecr')).to(be(true))
  end

  it 'allows multiple push tasks to be declared' do
    namespace :image1 do
      subject.define(
          image_name: 'image1',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image1',
          tags: ['latest'])
    end

    namespace :image2 do
      subject.define(
          image_name: 'image2',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2',
          tags: ['latest'])
    end

    expect(Rake::Task.task_defined?('image1:push')).to(be(true))
    expect(Rake::Task.task_defined?('image2:push')).to(be(true))
  end

  it 'configures the task with the provided arguments if specified' do
    argument_names = [:deployment_identifier, :region]

    namespace :image do
      subject.define(
          argument_names: argument_names,
          image_name: 'image2',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2',
          tags: ['latest'])
    end

    expect(Rake::Task['image:push'].arg_names)
        .to(eq(argument_names))
  end

  it 'fails if no image name is provided' do
    subject.define(
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest'])

    expect {
      Rake::Task["push"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no repository url is provided' do
    subject.define(
        image_name: 'thing',
        tags: ['latest'])

    expect {
      Rake::Task["push"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'authenticates using the provided credentials when present' do
    credentials = {
        username: 'user',
        password: 'pass',
        email: 'user@userorg.com',
        serveraddress: '123.dkr.ecr.eu-west-2.amazonaws.com'
    }

    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',

          credentials: credentials,
          tags: ['latest'])
    end

    expect(Docker)
        .to(receive(:authenticate!)
            .with(credentials))

    Rake::Task['image:push'].invoke
  end

  it 'authenticates using the provided credentials factory when present' do
    namespace :image do
      subject.define(
          argument_names: [:org_name],
          image_name: 'nginx',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
          tags: ['latest']
      ) do |t, args|

        t.credentials = {
            username: "#{t.image_name}",
            password: 'pass',
            email: "user@#{args.org_name}.com",
            serveraddress: "#{t.repository_url}"
        }
      end
    end

    expect(Docker)
        .to(receive(:authenticate!)
            .with({
                username: 'nginx',
                password: 'pass',
                email: 'user@userorg.com',
                serveraddress: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
            }))

    Rake::Task['image:push'].invoke('userorg')
  end

  it 'does not authenticate when no credentials are provided' do
    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
          tags: ['latest'])
    end

    expect(Docker).not_to(receive(:authenticate!))

    Rake::Task['image:push'].invoke
  end

  it 'pushes the image tagged with the repository_url with each of the provided tags' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_url: repository_url,
          tags: ['latest', '1.2.3'])
    end

    image = double('image')
    allow(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_url)
            .and_return([image]))
    expect(image)
        .to(receive(:push).with(nil, tag: 'latest'))
    expect(image)
        .to(receive(:push).with(nil, tag: '1.2.3'))

    Rake::Task['image:push'].invoke
  end

  it 'uses the provided repository URL factory when supplied' do
    expected_repository_url = "123.dkr.myorg/nginx"

    namespace :image do
      subject.define(
          argument_names: [:org_name],
          image_name: 'nginx',
          tags: ['latest']
      ) do |t, args|
        t.repository_url = "123.dkr.#{args.org_name}/#{t.image_name}"
      end
    end

    image = double('image')
    allow(Docker::Image)
        .to(receive(:all)
            .with(filter: expected_repository_url)
            .and_return([image]))
    expect(image)
        .to(receive(:push).with(nil, tag: 'latest'))

    Rake::Task['image:push'].invoke('myorg')
  end

  it 'uses the provided tags factory when supplied' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      subject.define(
          argument_names: [:org_name],
          image_name: 'nginx',
          repository_url: repository_url
      ) do |t, args|
        t.tags = ["#{t.image_name}_#{args.org_name}"]
      end
    end

    image = double('image')
    allow(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_url)
            .and_return([image]))
    expect(image)
        .to(receive(:push).with(nil, tag: 'nginx_myorg'))

    Rake::Task['image:push'].invoke('myorg')
  end

  it 'raises an exception if no image can be found' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag = 'really-important-tag'

    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_url: repository_url,
          tags: [tag])
    end

    expect(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_url)
            .and_return([]))

    expect {
      Rake::Task['image:push'].invoke
    }.to(raise_error(
        RakeDocker::ImageNotFound,
        'No image found for repository: ' +
            '\'123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx\''))
  end

  it 'print push progress to stdout' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_url: repository_url,
          tags: ['latest'])
    end

    image = double('image')
    allow(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_url)
            .and_return([image]))
    expect(image)
        .to(receive(:push).with(nil, tag: 'latest')
            .and_yield('progress-message-1')
            .and_yield('progress-message-2'))
    expect($stdout)
        .to(receive(:print)
            .with('progress-message-1'))
    expect($stdout)
        .to(receive(:print)
            .with('progress-message-2'))

    Rake::Task['image:push'].invoke
  end

  def stub_print
    allow_any_instance_of(Kernel).to(receive(:print))
    allow($stdout).to(receive(:print))
    allow($stderr).to(receive(:print))
  end

  def stub_docker_authenticate
    allow(Docker).to(receive(:authenticate!))
  end

  def stub_docker_image_search
    image = double('image', push: nil)
    allow(Docker::Image).to(receive(:all).and_return([image]))
  end
end
