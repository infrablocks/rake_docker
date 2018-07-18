require 'spec_helper'

describe RakeDocker::Tasks::Build do
  include_context :rake

  before(:each) do
    stub_puts
    stub_docker_build
  end

  def define_task(name = nil, options = {}, &block)
    ns = options[:namespace] || :image
    additional_tasks = options[:additional_tasks] || [:prepare]

    namespace ns do
      additional_tasks.each do |t|
        task t
      end

      subject.new(*(name ? [name] : [])) do |t|
        block.call(t) if block
      end
    end
  end

  it 'adds a build task in the namespace in which it is created' do
    define_task do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'
    end

    expect(Rake::Task['image:build']).not_to be_nil
  end

  it 'gives the build task a description' do
    define_task do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'
    end

    expect(rake.last_description).to(eq('Build nginx image'))
  end

  it 'allows the task name to be overridden' do
    define_task(:construct) do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'
    end

    expect(Rake::Task['image:construct']).not_to be_nil
  end

  it 'allows multiple build tasks to be declared' do
    define_task(nil, namespace: :image1) do |t|
      t.image_name = 'image1'
      t.repository_name = 'my-org/image1'
      t.work_directory = 'build'
    end

    define_task(nil, namespace: :image2) do |t|
      t.image_name = 'image2'
      t.repository_name = 'my-org/image2'
      t.work_directory = 'build'
    end

    image1_build = Rake::Task['image1:build']
    image2_build = Rake::Task['image2:build']

    expect(image1_build).not_to be_nil
    expect(image2_build).not_to be_nil
  end

  it 'fails if no image name is provided' do
    expect {
      define_task do |t|
        t.repository_name = 'my-org/thing'
        t.work_directory = 'build'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no repository name is provided' do
    expect {
      define_task do |t|
        t.image_name = 'thing'
        t.work_directory = 'build'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no work directory is provided' do
    expect {
      define_task do |t|
        t.image_name = 'thing'
        t.repository_name = 'my-org/thing'
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

    define_task do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/thing'
      t.work_directory = 'build'

      t.credentials = credentials
    end

    expect(Docker)
        .to(receive(:authenticate!)
                .with(credentials))

    Rake::Task['image:build'].invoke
  end

  it 'authenticates using the provided credentials factory when present' do
    define_task do |t|
      t.argument_names = [:org_name]

      t.image_name = 'thing'
      t.repository_name = 'my-org/thing'
      t.work_directory = 'build'

      t.credentials = lambda do |args, params|
        {
            username: "#{params.image_name}",
            password: 'pass',
            email: "user@#{args.org_name}.com",
            serveraddress: "123.dkr.ecr.eu-west-2.amazonaws.com/#{params.repository_name}"
        }
      end
    end

    expect(Docker)
        .to(receive(:authenticate!)
                .with({
                          username: 'thing',
                          password: 'pass',
                          email: 'user@userorg.com',
                          serveraddress: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/thing'
                      }))

    Rake::Task['image:build'].invoke('userorg')
  end

  it 'does not authenticate when no credentials are provided' do
    define_task do |t|
      t.image_name = 'thing'
      t.repository_name = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/thing'
      t.work_directory = 'build'
    end

    expect(Docker).not_to(receive(:authenticate!))

    Rake::Task['image:build'].invoke
  end

  it 'builds the image in the correct work directory tagging with the repository name' do
    define_task do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'
    end

    expect(Docker::Image)
        .to(receive(:build_from_dir)
                .with('build/nginx', {t: 'my-org/nginx'}))

    Rake::Task['image:build'].invoke
  end

  it 'puts progress to stdout' do
    define_task do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'
    end

    allow(Docker::Image)
        .to(receive(:build_from_dir)
                .and_yield('{"stream":"progress-message-1"}')
                .and_yield('{"stream":"progress-message-2"}'))
    expect($stdout)
        .to(receive(:puts)
                .with('progress-message-1'))
    expect($stdout)
        .to(receive(:puts)
                .with('progress-message-2'))

    Rake::Task['image:build'].invoke
  end

  it 'depends on the prepare task by default' do
    define_task do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'
    end

    build_task = Rake::Task['image:build']

    expect(build_task.prerequisite_tasks).to(eq([
      Rake::Task['image:prepare']
    ]))
  end

  it 'allows the prepare task to be overridden' do
    define_task(nil, additional_tasks: [:prep]) do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'

      t.prepare_task = :prep
    end

    task = Rake::Task['image:build']

    expect(task.prerequisite_tasks).to(include(Rake::Task['image:prep']))
  end

  it 'does not depend on prepare task when nil' do
    define_task do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.work_directory = 'build'

      t.prepare_task = nil
    end

    task = Rake::Task['image:build']

    expect(task.prerequisite_tasks).to(eq([]))
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
