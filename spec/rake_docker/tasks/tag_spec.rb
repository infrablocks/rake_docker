require 'spec_helper'

describe RakeDocker::Tasks::Tag do
  include_context :rake

  before(:each) do
    stub_puts
    stub_docker_image_search
  end

  it 'adds a tag task in the namespace in which it is created' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_name = 'my-org/nginx'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.tags = ['latest']
      end
    end

    expect(Rake::Task['image:tag']).not_to be_nil
  end

  it 'gives the tag task a description' do
    subject.new do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

      t.tags = ['latest']
    end

    expect(rake.last_description).to(eq('Tag nginx image for repository'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.new(:tag_as_latest) do |t|
        t.image_name = 'nginx'
        t.repository_name = 'my-org/nginx'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.tags = ['latest']
      end
    end

    expect(Rake::Task['image:tag_as_latest']).not_to be_nil
  end

  it 'allows multiple tag tasks to be declared' do
    namespace :image1 do
      subject.new do |t|
        t.image_name = 'image1'
        t.repository_name = 'my-org/image1'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image1'

        t.tags = ['latest']
      end
    end

    namespace :image2 do
      subject.new do |t|
        t.image_name = 'image2'
        t.repository_name = 'my-org/image2'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image2'

        t.tags = ['latest']
      end
    end

    image1_tag = Rake::Task['image1:tag']
    image2_tag = Rake::Task['image2:tag']

    expect(image1_tag).not_to be_nil
    expect(image2_tag).not_to be_nil
  end

  it 'configures the task with the provided arguments if specified' do
    argument_names = [:deployment_identifier, :region]

    namespace :image do
      subject.new do |t|
        t.argument_names = argument_names

        t.image_name = 'image'
        t.repository_name = 'my-org/image'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/image'

        t.tags = ['latest']
      end
    end

    expect(Rake::Task['image:tag'].arg_names)
        .to(eq(argument_names))
  end

  it 'fails if no image name is provided' do
    expect {
      subject.new do |t|
        t.repository_name = 'my-org/thing'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.tags = ['latest']
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no repository name is provided' do
    expect {
      subject.new do |t|
        t.image_name = 'thing'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

        t.tags = ['latest']
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no repository URL is provided' do
    expect {
      subject.new do |t|
        t.image_name = 'thing'
        t.repository_name = 'my-org/thing'

        t.tags = ['latest']
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no tags array is provided' do
    expect {
      subject.new do |t|
        t.image_name = 'thing'
        t.repository_name = 'my-org/thing'
        t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'tags the image for the repository URL and supplied tags when present' do
    repository_name = 'my-org/nginx'
    repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
    tag1 = 'really-important-tag'
    tag2 = 'other-important-tag'

    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_name = repository_name
        t.repository_url = repository_url

        t.tags = [tag1, tag2]
      end
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
      subject.new do |t|
        t.argument_names = [:org_name]

        t.image_name = 'nginx'
        t.repository_name = repository_name

        t.repository_url = lambda do |args, params|
          "123.dkr.ecr.eu-west-2.amazonaws.com/#{args.org_name}/#{params.image_name}"
        end

        t.tags = [tag]
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
      subject.new do |t|
        t.argument_names = [:org_name]

        t.image_name = 'nginx'
        t.repository_name = repository_name
        t.repository_url = repository_url

        t.tags = lambda do |args, params|
          ["#{params.image_name}-123", 'latest', args.org_name]
        end
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
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_name = repository_name
        t.repository_url = repository_url

        t.tags = [tag]
      end
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
