require 'spec_helper'

describe RakeDocker::Tasks::Tag do
  include_context :rake

  before(:each) do
    stub_puts
    stub_docker_image_search
  end

  it 'adds a tag task in the namespace in which it is created' do
    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_name: 'my-org/nginx',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
          tags: ['latest'])
    end

    expect(Rake::Task.task_defined?('image:tag')).to(be(true))
  end

  it 'gives the tag task a description' do
    subject.define(
        image_name: 'nginx',
        repository_name: 'my-org/nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest'])

    expect(Rake::Task["tag"].full_comment)
        .to(eq('Tag nginx image for repository'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.define(
          name: :tag_as_latest,
          image_name: 'nginx',
          repository_name: 'my-org/nginx',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
          tags: ['latest'])
    end

    expect(Rake::Task.task_defined?('image:tag_as_latest'))
        .to(be(true))
  end

  it 'allows multiple tag tasks to be declared' do
    namespace :image1 do
      subject.define(
          image_name: 'image1',
          repository_name: 'my-org/image1',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image1',
          tags: ['latest'])
    end

    namespace :image2 do
      subject.define(
          image_name: 'image2',
          repository_name: 'my-org/image2',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2',
          tags: ['latest'])
    end

    expect(Rake::Task.task_defined?('image1:tag')).to(be(true))
    expect(Rake::Task.task_defined?('image2:tag')).to(be(true))
  end

  it 'configures the task with the provided arguments if specified' do
    argument_names = [:deployment_identifier, :region]

    namespace :image do
      subject.define(
          argument_names: argument_names,
          image_name: 'image',
          repository_name: 'my-org/image',
          repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image',
          tags: ['latest'])
    end

    expect(Rake::Task['image:tag'].arg_names)
        .to(eq(argument_names))
  end

  it 'fails if no image name is provided' do
    subject.define(
        repository_name: 'my-org/thing',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',

        tags: ['latest'])

    expect {
      Rake::Task["tag"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no repository name is provided' do
    subject.define(
        image_name: 'thing',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        tags: ['latest'])

    expect {
      Rake::Task["tag"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no repository URL is provided' do
    subject.define(
        image_name: 'thing',
        repository_name: 'my-org/thing',
        tags: ['latest'])

    expect {
      Rake::Task["tag"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no tags array is provided' do
    subject.define(
        image_name: 'thing',
        repository_name: 'my-org/thing',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx')

    expect {
      Rake::Task["tag"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'tags the image for the repository URL and supplied tags when present' do
    repository_name = 'my-org/nginx'
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag1 = 'really-important-tag'
    tag2 = 'other-important-tag'

    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_name: repository_name,
          repository_url: repository_url,

          tags: [tag1, tag2])
    end

    image = double('image')

    expect(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_name)
            .and_return([image]))
    expect(image)
        .to(receive(:tag)
            .with(repo: repository_url, tag: tag1, force: true))
    expect(image)
        .to(receive(:tag)
            .with(repo: repository_url, tag: tag2, force: true))

    Rake::Task['image:tag'].invoke
  end

  it 'uses the provided repository URL factory when supplied' do
    repository_name = 'my-org/nginx'
    tag = 'really-important-tag'

    namespace :image do
      subject.define(
          argument_names: [:org_name],
          image_name: 'nginx',
          repository_name: repository_name,
          tags: [tag],
      ) do |t, args|
        t.repository_url =
            "123.dkr.ecr.eu-west-2.amazonaws.com/" +
                "#{args.org_name}/#{t.image_name}"
      end
    end

    image = double('image')

    expect(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_name)
            .and_return([image]))
    expect(image)
        .to(receive(:tag)
            .with(repo: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
                tag: tag,
                force: true))

    Rake::Task['image:tag'].invoke('my-org')
  end

  it 'uses the provided tags factory when supplied' do
    repository_name = 'my-org/nginx'
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

    namespace :image do
      subject.define(
          argument_names: [:org_name],

          image_name: 'nginx',
          repository_name: repository_name,
          repository_url: repository_url
      ) do |t, args|
        t.tags = ["#{t.image_name}-123", 'latest', args.org_name]
      end
    end

    image = double('image')

    expect(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_name)
            .and_return([image]))
    expect(image)
        .to(receive(:tag)
            .with(repo: repository_url,
                tag: 'nginx-123',
                force: true))
    expect(image)
        .to(receive(:tag)
            .with(repo: repository_url,
                tag: 'latest',
                force: true))
    expect(image)
        .to(receive(:tag)
            .with(repo: repository_url,
                tag: 'my-org',
                force: true))

    Rake::Task['image:tag'].invoke('my-org')
  end

  it 'raises an exception if no image can be found' do
    repository_name = 'my-org/nginx'
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag = 'really-important-tag'

    namespace :image do
      subject.define(
          image_name: 'nginx',
          repository_name: repository_name,
          repository_url: repository_url,

          tags: [tag])
    end

    expect(Docker::Image)
        .to(receive(:all)
            .with(filter: repository_name)
            .and_return([]))

    expect {
      Rake::Task['image:tag'].invoke
    }.to(raise_error(RakeDocker::ImageNotFound,
        'No image found with name: \'nginx\''))
  end

  def stub_puts
    allow_any_instance_of(Kernel).to(receive(:puts))
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end

  def stub_docker_image_search
    image = double('image', tag: nil)
    allow(Docker::Image).to(receive(:all).and_return([image]))
  end
end
