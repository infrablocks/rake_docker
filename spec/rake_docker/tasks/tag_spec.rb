# frozen_string_literal: true

require 'spec_helper'

describe RakeDocker::Tasks::Tag do
  include_context 'rake'

  before do
    stub_puts
    stub_docker_image_search
  end

  it 'adds a tag task in the namespace in which it is created' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_name: 'my-org/nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest']
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:tag'))
  end

  it 'gives the tag task a description' do
    described_class.define(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
      tags: ['latest']
    )

    expect(Rake::Task['tag'].full_comment)
      .to(eq('Tag nginx image for repository'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      described_class.define(
        name: :tag_as_latest,
        image_name: 'nginx',
        repository_name: 'my-org/nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest']
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:tag_as_latest'))
  end

  it 'allows multiple tag tasks to be declared' do
    namespace :image1 do
      described_class.define(
        image_name: 'image1',
        repository_name: 'my-org/image1',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image1',
        tags: ['latest']
      )
    end

    namespace :image2 do
      described_class.define(
        image_name: 'image2',
        repository_name: 'my-org/image2',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2',
        tags: ['latest']
      )
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[image1:tag
               image2:tag]
          ))
  end

  it 'configures the task with the provided arguments if specified' do
    argument_names = %i[deployment_identifier region]

    namespace :image do
      described_class.define(
        argument_names:,
        image_name: 'image',
        repository_name: 'my-org/image',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image',
        tags: ['latest']
      )
    end

    expect(Rake::Task['image:tag'].arg_names)
      .to(eq(argument_names))
  end

  it 'fails if no image name is provided' do
    described_class.define(
      repository_name: 'my-org/thing',
      repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',

      tags: ['latest']
    )

    expect do
      Rake::Task['tag'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no repository name is provided' do
    described_class.define(
      image_name: 'thing',
      repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
      tags: ['latest']
    )

    expect do
      Rake::Task['tag'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no repository URL is provided' do
    described_class.define(
      image_name: 'thing',
      repository_name: 'my-org/thing',
      tags: ['latest']
    )

    expect do
      Rake::Task['tag'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no tags array is provided' do
    described_class.define(
      image_name: 'thing',
      repository_name: 'my-org/thing',
      repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    )

    expect do
      Rake::Task['tag'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'tags the image for the repository URL and supplied tags when present' do
    repository_name = 'my-org/nginx'
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag1 = 'really-important-tag'
    tag2 = 'other-important-tag'

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_name:,
        repository_url:,

        tags: [tag1, tag2]
      )
    end

    image = instance_double(Docker::Image)

    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_name)
            .and_return([image]))
    allow(image).to(receive(:tag))

    Rake::Task['image:tag'].invoke

    expect(image)
      .to(have_received(:tag)
            .with(repo: repository_url, tag: tag1, force: true))
    expect(image)
      .to(have_received(:tag)
            .with(repo: repository_url, tag: tag2, force: true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'uses the provided repository URL factory when supplied' do
    repository_name = 'my-org/nginx'
    tag = 'really-important-tag'

    namespace :image do
      described_class.define(
        argument_names: [:org_name],
        image_name: 'nginx',
        repository_name:,
        tags: [tag]
      ) do |t, args|
        t.repository_url =
          '123.dkr.ecr.eu-west-2.amazonaws.com/' \
          "#{args.org_name}/#{t.image_name}"
      end
    end

    image = instance_double(Docker::Image)

    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_name)
            .and_return([image]))
    allow(image).to(receive(:tag))

    Rake::Task['image:tag'].invoke('my-org')

    expect(image)
      .to(have_received(:tag)
            .with(repo: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
                  tag:,
                  force: true))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'uses the provided tags factory when supplied' do
    repository_name = 'my-org/nginx'
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      described_class.define(
        argument_names: [:org_name],

        image_name: 'nginx',
        repository_name:,
        repository_url:
      ) do |t, args|
        t.tags = ["#{t.image_name}-123", 'latest', args.org_name]
      end
    end

    image = instance_double(Docker::Image)

    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_name)
            .and_return([image]))
    allow(image).to(receive(:tag))

    Rake::Task['image:tag'].invoke('my-org')

    expect(image)
      .to(have_received(:tag)
            .with(repo: repository_url,
                  tag: 'nginx-123',
                  force: true))
    expect(image)
      .to(have_received(:tag)
            .with(repo: repository_url,
                  tag: 'latest',
                  force: true))
    expect(image)
      .to(have_received(:tag)
            .with(repo: repository_url,
                  tag: 'my-org',
                  force: true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'raises an exception if no image can be found' do
    repository_name = 'my-org/nginx'
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag = 'really-important-tag'

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        repository_name:,
        repository_url:,

        tags: [tag]
      )
    end

    allow(Docker::Image)
      .to(receive(:all)
            .with(filter: repository_name)
            .and_return([]))

    expect do
      Rake::Task['image:tag'].invoke
    end.to(raise_error(RakeDocker::ImageNotFound,
                       'No image found with name: \'nginx\''))
  end

  def stub_puts
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end

  def stub_docker_image_search
    image = instance_double(Docker::Image, tag: nil)
    allow(Docker::Image).to(receive(:all).and_return([image]))
  end
end
