# frozen_string_literal: true

require 'spec_helper'

describe RakeDocker::Tasks::Build do
  include_context 'rake'

  before do
    stub_print
    stub_docker_build
  end

  def define_task(opts = {}, &block)
    opts =
      { namespace: :image, additional_tasks: [:prepare] }
      .merge(opts)

    namespace opts[:namespace] do
      opts[:additional_tasks].each do |t|
        task t
      end

      described_class.define(opts, &block)
    end
  end

  it 'adds a build task in the namespace in which it is created' do
    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    expect(Rake.application)
      .to(have_task_defined('image:build'))
  end

  it 'gives the build task a description' do
    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    expect(Rake::Task['image:build'].full_comment)
      .to(eq('Build nginx image'))
  end

  it 'allows the task name to be overridden' do
    define_task(
      name: :construct,
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    expect(Rake.application)
      .to(have_task_defined('image:construct'))
  end

  it 'allows multiple build tasks to be declared' do
    define_task(
      namespace: :image1,
      image_name: 'image1',
      repository_name: 'my-org/image1',
      work_directory: 'build'
    )

    define_task(
      namespace: :image2,
      image_name: 'image2',
      repository_name: 'my-org/image2',
      work_directory: 'build'
    )

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[image1:build
               image2:build]
          ))
  end

  it 'fails if no image name is provided' do
    define_task(
      repository_name: 'my-org/thing',
      work_directory: 'build'
    )

    expect do
      Rake::Task['image:build'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no repository name is provided' do
    define_task(
      image_name: 'thing',
      work_directory: 'build'
    )

    expect do
      Rake::Task['image:build'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no work directory is provided' do
    define_task(
      image_name: 'thing',
      repository_name: 'my-org/thing'
    )

    expect do
      Rake::Task['image:build'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'authenticates using the provided credentials when present' do
    credentials = {
      username: 'user',
      password: 'pass',
      email: 'user@userorg.com',
      serveraddress: '123.dkr.ecr.eu-west-2.amazonaws.com'
    }

    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/thing',
      work_directory: 'build',
      credentials: credentials
    )

    allow(Docker).to(receive(:authenticate!))

    Rake::Task['image:build'].invoke

    expect(Docker)
      .to(have_received(:authenticate!)
            .with(credentials))
  end

  it 'authenticates using the provided credentials factory when present' do
    define_task(
      argument_names: [:org_name],
      image_name: 'thing',
      repository_name: 'my-org/thing',
      work_directory: 'build'
    ) do |t, args|
      t.credentials = {
        username: t.image_name.to_s,
        password: 'pass',
        email: "user@#{args.org_name}.com",
        serveraddress:
          "123.dkr.ecr.eu-west-2.amazonaws.com/#{t.repository_name}"
      }
    end

    allow(Docker)
      .to(receive(:authenticate!))

    Rake::Task['image:build'].invoke('userorg')

    expect(Docker)
      .to(have_received(:authenticate!)
            .with({
                    username: 'thing',
                    password: 'pass',
                    email: 'user@userorg.com',
                    serveraddress:
                      '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/thing'
                  }))
  end

  it 'does not authenticate when no credentials are provided' do
    define_task(
      image_name: 'thing',
      repository_name: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/thing',
      work_directory: 'build'
    )

    allow(Docker).to(receive(:authenticate!))

    Rake::Task['image:build'].invoke

    expect(Docker)
      .not_to(have_received(:authenticate!))
  end

  it 'builds the image in the correct work directory tagging with the '\
     'repository name' do
    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    allow(Docker::Image)
      .to(receive(:build_from_dir))

    Rake::Task['image:build'].invoke

    expect(Docker::Image)
      .to(have_received(:build_from_dir)
            .with('build/nginx', { t: 'my-org/nginx' }))
  end

  it 'passes the specified build args when provided' do
    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build',
      build_args: {
        SOMETHING_IMPORTANT: 'you-need-to-know-this'
      }
    )

    allow(Docker::Image)
      .to(receive(:build_from_dir))

    Rake::Task['image:build'].invoke

    expect(Docker::Image)
      .to(have_received(:build_from_dir)
            .with('build/nginx', {
                    t: 'my-org/nginx',
                    buildargs: '{"SOMETHING_IMPORTANT":"you-need-to-know-this"}'
                  }))
  end

  it 'passes the specified platform when provided' do
    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build',
      platform: 'linux/amd64'
    )

    allow(Docker::Image)
      .to(receive(:build_from_dir))

    Rake::Task['image:build'].invoke

    expect(Docker::Image)
      .to(have_received(:build_from_dir)
            .with('build/nginx', {
                    t: 'my-org/nginx',
                    platform: 'linux/amd64'
                  }))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'print progress to stdout' do
    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    allow(Docker::Image)
      .to(receive(:build_from_dir)
            .and_yield('progress-message-1')
            .and_yield('progress-message-2'))

    Rake::Task['image:build'].invoke

    expect($stdout)
      .to(have_received(:print)
            .with('progress-message-1'))
    expect($stdout)
      .to(have_received(:print)
            .with('progress-message-2'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'depends on the prepare task by default' do
    define_task(
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    build_task = Rake::Task['image:build']

    expect(build_task.prerequisite_tasks)
      .to(eq([Rake::Task['image:prepare']]))
  end

  it 'allows the prepare task to be overridden' do
    define_task(
      additional_tasks: [:prep],
      prepare_task_name: :prep,
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    task = Rake::Task['image:build']

    expect(task.prerequisite_tasks)
      .to(include(Rake::Task['image:prep']))
  end

  it 'does not depend on prepare task when nil' do
    define_task(
      prepare_task_name: nil,
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      work_directory: 'build'
    )

    task = Rake::Task['image:build']

    expect(task.prerequisite_tasks).to(eq([]))
  end

  def stub_print
    allow($stdout).to(receive(:print))
    allow($stderr).to(receive(:print))
  end

  def stub_docker_build
    allow(Docker::Image).to(receive(:build_from_dir))
  end
end
