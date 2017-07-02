require 'spec_helper'

describe RakeDocker::Tasks::Build do
  include_context :rake

  before(:each) do
    stub_puts
    stub_docker_build
  end

  it 'adds a build task in the namespace in which it is created' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_name = 'my-org/nginx'
        t.work_directory = 'build'
      end
    end

    expect(Rake::Task['image:build']).not_to be_nil
  end

  it 'gives the build task a description' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_name = 'my-org/nginx'
        t.work_directory = 'build'
      end
    end

    expect(rake.last_description).to(eq('Build nginx image'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.new(:construct) do |t|
        t.image_name = 'nginx'
        t.repository_name = 'my-org/nginx'
        t.work_directory = 'build'
      end
    end

    expect(Rake::Task['image:construct']).not_to be_nil
  end

  it 'allows multiple build tasks to be declared' do
    namespace :image1 do
      subject.new do |t|
        t.image_name = 'image1'
        t.repository_name = 'my-org/image1'
        t.work_directory = 'build'
      end
    end

    namespace :image2 do
      subject.new do |t|
        t.image_name = 'image2'
        t.repository_name = 'my-org/image2'
        t.work_directory = 'build'
      end
    end

    image1_build = Rake::Task['image1:build']
    image2_build = Rake::Task['image2:build']

    expect(image1_build).not_to be_nil
    expect(image2_build).not_to be_nil
  end

  it 'fails if no image name is provided' do
    expect {
      subject.new do |t|
        t.repository_name = 'my-org/thing'
        t.work_directory = 'build'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no repository name is provided' do
    expect {
      subject.new do |t|
        t.image_name = 'thing'
        t.work_directory = 'build'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no work directory is provided' do
    expect {
      subject.new do |t|
        t.image_name = 'thing'
        t.repository_name = 'my-org/thing'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'builds the image in the correct work directory tagging with the repository name' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_name = 'my-org/nginx'
        t.work_directory = 'build'
      end
    end

    expect(Docker::Image)
        .to(receive(:build_from_dir)
                .with('build/nginx', {t: 'my-org/nginx'}))

    Rake::Task['image:build'].invoke
  end

  it 'puts progress to stdout' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.repository_name = 'my-org/nginx'
        t.work_directory = 'build'
      end
    end

    allow(Docker::Image)
        .to(receive(:build_from_dir)
                .and_yield('progress-message-1')
                .and_yield('progress-message-2'))
    expect($stdout)
        .to(receive(:puts)
                .with('progress-message-1'))
    expect($stdout)
        .to(receive(:puts)
                .with('progress-message-2'))

    Rake::Task['image:build'].invoke
  end

  def stub_puts
    allow_any_instance_of(Kernel).to(receive(:puts))
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end

  def stub_docker_build
    allow(Docker::Image).to(receive(:build_from_dir))
  end
end
