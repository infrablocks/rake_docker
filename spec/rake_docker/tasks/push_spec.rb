require 'spec_helper'

describe RakeDocker::Tasks::Push do
  include_context :rake

  before(:each) do
    stub_puts
    stub_docker_authenticate
    stub_docker_image_search
  end

  it 'adds a push task in the namespace in which it is created' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.tags = ['latest']
      end
    end

    expect(Rake::Task['image:push']).not_to be_nil
  end

  it 'gives the push task a description' do
    subject.new do |t|
      t.image_name = 'nginx'
      t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

      t.tags = ['latest']
    end

    expect(rake.last_description).to(eq('Push nginx image to repository'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.new(:push_to_ecr) do |t|
        t.image_name = 'nginx'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.tags = ['latest']
      end
    end

    expect(Rake::Task['image:push_to_ecr']).not_to be_nil
  end

  it 'allows multiple push tasks to be declared' do
    namespace :image1 do
      subject.new do |t|
        t.image_name = 'image1'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image1'

        t.tags = ['latest']
      end
    end

    namespace :image2 do
      subject.new do |t|
        t.image_name = 'image2'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2'

        t.tags = ['latest']
      end
    end

    image1_push = Rake::Task['image1:push']
    image2_push = Rake::Task['image2:push']

    expect(image1_push).not_to be_nil
    expect(image2_push).not_to be_nil
  end

  it 'fails if no image name is provided' do
    expect {
      subject.new do |t|
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
        t.tags = ['latest']
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no repository url is provided' do
    expect {
      subject.new do |t|
        t.image_name = 'thing'
        t.tags = ['latest']
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'authenticates using the provided credentials when present' do
    credentials = {
        username: 'user',
        password: 'pass',
        email: 'user@userorg.com',
        serveraddress: '123.dkr.ecr.eu-west-2.amazonaws.com'
    }

    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.credentials = credentials
        t.tags = ['latest']
      end
    end

    expect(Docker)
        .to(receive(:authenticate!)
                .with(credentials))

    Rake::Task['image:push'].invoke
  end

  it 'authenticates using the provided credentials factory when present' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.credentials = lambda do |params|
          {
              username: "#{params.image_name}",
              password: 'pass',
              email: 'user@userorg.com',
              serveraddress: "#{params.repository_url}"
          }
        end

        t.tags = ['latest']
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

    Rake::Task['image:push'].invoke
  end

  it 'does not authenticate when no credentials are provided' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.tags = ['latest']
      end
    end

    expect(Docker).not_to(receive(:authenticate!))

    Rake::Task['image:push'].invoke
  end

  it 'pushes the image tagged with the repository_url with each of the provided tags' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = repository_url

        t.tags = ['latest', '1.2.3']
      end
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
    expected_repository_url = "123.dkr.my.org/nginx"

    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = lambda do |params|
          "123.dkr.my.org/#{params.image_name}"
        end

        t.tags = ['latest']
      end
    end

    image = double('image')
    allow(Docker::Image)
        .to(receive(:all)
                .with(filter: expected_repository_url)
                .and_return([image]))
    expect(image)
        .to(receive(:push).with(nil, tag: 'latest'))

    Rake::Task['image:push'].invoke
  end

  it 'uses the provided tags factory when supplied' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = repository_url

        t.tags = lambda do |params|
          ["#{params.image_name}_latest"]
        end
      end
    end

    image = double('image')
    allow(Docker::Image)
        .to(receive(:all)
                .with(filter: repository_url)
                .and_return([image]))
    expect(image)
        .to(receive(:push).with(nil, tag: 'nginx_latest'))

    Rake::Task['image:push'].invoke
  end

  it 'raises an exception if no image can be found' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag = 'really-important-tag'

    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = repository_url

        t.tags = [tag]
      end
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

  it 'puts push progress to stdout' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_url = repository_url

        t.tags = ['latest']
      end
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
        .to(receive(:puts)
                .with('progress-message-1'))
    expect($stdout)
        .to(receive(:puts)
                .with('progress-message-2'))

    Rake::Task['image:push'].invoke
  end

  def stub_puts
    allow_any_instance_of(Kernel).to(receive(:puts))
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end

  def stub_docker_authenticate
    allow(Docker).to(receive(:authenticate!))
  end

  def stub_docker_image_search
    image = double('image', push: nil)
    allow(Docker::Image).to(receive(:all).and_return([image]))
  end
end
