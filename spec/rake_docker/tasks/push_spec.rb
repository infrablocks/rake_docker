# frozen_string_literal: true

require 'spec_helper'

describe RakeDocker::Tasks::Push do
  include_context 'rake'

  before do
    stub_print
    stub_docker_authenticate
    stub_docker_image_search
  end

  it 'adds a push task in the namespace in which it is created' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest']
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:push'))
  end

  it 'gives the push task a description' do
    described_class.define(
      image_name: 'nginx',
      repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
      tags: ['latest']
    )

    expect(Rake::Task['push'].full_comment)
      .to(eq('Push nginx image to repository'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      described_class.define(
        name: :push_to_ecr,
        image_name: 'nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest']
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:push_to_ecr'))
  end

  it 'allows multiple push tasks to be declared' do
    namespace :image1 do
      described_class.define(
        image_name: 'image1',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image1',
        tags: ['latest']
      )
    end

    namespace :image2 do
      described_class.define(
        image_name: 'image2',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2',
        tags: ['latest']
      )
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[image1:push
               image2:push]
          ))
  end

  it 'configures the task with the provided arguments if specified' do
    argument_names = %i[deployment_identifier region]

    namespace :image do
      described_class.define(
        argument_names:,
        image_name: 'image2',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2',
        tags: ['latest']
      )
    end

    expect(Rake::Task['image:push'].arg_names)
      .to(eq(argument_names))
  end

  it 'fails if no image name is provided' do
    described_class.define(
      repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
      tags: ['latest']
    )

    expect do
      Rake::Task['push'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no repository url is provided' do
    described_class.define(
      image_name: 'thing',
      tags: ['latest']
    )

    expect do
      Rake::Task['push'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'authenticates using the provided credentials when present' do
    credentials = {
      username: 'user',
      password: 'pass',
      email: 'user@userorg.com',
      serveraddress: '123.dkr.ecr.eu-west-2.amazonaws.com'
    }

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',

        credentials:,
        tags: ['latest']
      )
    end

    allow(Docker).to(receive(:authenticate!))

    Rake::Task['image:push'].invoke

    expect(Docker)
      .to(have_received(:authenticate!)
            .with(credentials))
  end

  it 'authenticates using the provided credentials factory when present' do
    namespace :image do
      described_class.define(
        argument_names: [:org_name],
        image_name: 'nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest']
      ) do |t, args|
        t.credentials = {
          username: t.image_name.to_s,
          password: 'pass',
          email: "user@#{args.org_name}.com",
          serveraddress: t.repository_url.to_s
        }
      end
    end

    allow(Docker).to(receive(:authenticate!))

    Rake::Task['image:push'].invoke('userorg')

    expect(Docker)
      .to(have_received(:authenticate!)
            .with(
              {
                username: 'nginx',
                password: 'pass',
                email: 'user@userorg.com',
                serveraddress:
                  '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
              }
            ))
  end

  it 'does not authenticate when no credentials are provided' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest']
      )
    end

    allow(Docker).to(receive(:authenticate!))

    Rake::Task['image:push'].invoke

    expect(Docker)
      .not_to(have_received(:authenticate!))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'pushes the image tagged with the repository_url with each of the ' \
     'provided tags' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_url:,
        tags: %w[latest 1.2.3]
      )
    end

    image = instance_double(Docker::Image)
    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_url)
            .and_return([image]))
    allow(image).to(receive(:push))

    Rake::Task['image:push'].invoke

    expect(image)
      .to(have_received(:push)
            .with(nil, tag: 'latest'))
    expect(image)
      .to(have_received(:push)
            .with(nil, tag: '1.2.3'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'uses the provided repository URL factory when supplied' do
    expected_repository_url = '123.dkr.myorg/nginx'

    namespace :image do
      described_class.define(
        argument_names: [:org_name],
        image_name: 'nginx',
        tags: ['latest']
      ) do |t, args|
        t.repository_url = "123.dkr.#{args.org_name}/#{t.image_name}"
      end
    end

    image = instance_double(Docker::Image)
    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: expected_repository_url)
            .and_return([image]))
    allow(image).to(receive(:push))

    Rake::Task['image:push'].invoke('myorg')

    expect(image)
      .to(have_received(:push)
            .with(nil, tag: 'latest'))
  end

  it 'uses the provided tags factory when supplied' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      described_class.define(
        argument_names: [:org_name],
        image_name: 'nginx',
        repository_url:
      ) do |t, args|
        t.tags = ["#{t.image_name}_#{args.org_name}"]
      end
    end

    image = instance_double(Docker::Image)
    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_url)
            .and_return([image]))
    allow(image).to(receive(:push))

    Rake::Task['image:push'].invoke('myorg')

    expect(image)
      .to(have_received(:push)
            .with(nil, tag: 'nginx_myorg'))
  end

  it 'raises an exception if no image can be found' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag = 'really-important-tag'

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_url:,
        tags: [tag]
      )
    end

    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_url)
            .and_return([]))

    expect do
      Rake::Task['image:push'].invoke
    end.to(raise_error(
             RakeDocker::ImageNotFound,
             'No image found for repository: ' \
             '\'123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx\''
           ))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'print push progress to stdout' do
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_url:,
        tags: ['latest']
      )
    end

    image = instance_double(Docker::Image)
    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_url)
            .and_return([image]))
    allow(image)
      .to(receive(:push)
            .and_yield('progress-message-1')
            .and_yield('progress-message-2'))
    allow($stdout).to(receive(:print))

    Rake::Task['image:push'].invoke

    expect($stdout)
      .to(have_received(:print)
            .with('progress-message-1'))
    expect($stdout)
      .to(have_received(:print)
            .with('progress-message-2'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  def stub_print
    allow($stdout).to(receive(:print))
    allow($stderr).to(receive(:print))
  end

  def stub_docker_authenticate
    allow(Docker).to(receive(:authenticate!))
  end

  def stub_docker_image_search
    image = instance_double(Docker::Image, push: nil)
    allow(Docker::Image).to(receive(:all).and_return([image]))
  end
end
