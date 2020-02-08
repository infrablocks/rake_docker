require 'spec_helper'

describe RakeDocker::Tasks::Provision do
  include_context :rake

  before(:each) do
    stub_puts
  end

  it 'adds a provision task in the namespace in which it is created' do
    namespace :container do
      subject.define(
          container_name: 'web-server',
          image: 'nginx:latest')
    end

    expect(Rake::Task.task_defined?('container:provision')).to(be(true))
  end

  it 'gives the provision task a description' do
    namespace :container do
      subject.define(
          container_name: 'web-server',
          image: 'nginx:latest')
    end

    expect(Rake::Task["container:provision"].full_comment)
        .to(eq('Start web-server container.'))
  end

  it 'allows the task name to be overridden' do
    namespace :container do
      subject.define(
          name: :start,
          container_name: 'web-server',
          image: 'nginx:latest')
    end

    expect(Rake::Task.task_defined?('container:start')).to(be(true))
  end

  it 'allows multiple provision tasks to be declared' do
    namespace :container_1 do
      subject.define(
          container_name: 'web-server-1',
          image: 'nginx:latest')
    end

    namespace :container_2 do
      subject.define(
          container_name: 'web-server-2',
          image: 'nginx:latest')
    end

    expect(Rake::Task.task_defined?('container_1:provision')).to(be(true))
    expect(Rake::Task.task_defined?('container_2:provision')).to(be(true))
  end

  it 'fails if no container name is provided' do
    subject.define(image: 'nginx:latest')

    stub_provisioner

    expect {
      Rake::Task["provision"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no image is provided' do
    subject.define(container_name: 'web-server')

    stub_provisioner

    expect {
      Rake::Task["provision"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'creates and executes a provisioner on invocation' do
    container_name = "web-server"
    image = "nginx:latest"
    ports = ["1234:1234"]
    environment = {
        "THING1" => "one",
        "THING2" => "two"
    }
    reporter = RakeDocker::Container::NullReporter.new
    ready_check = proc { true }

    provisioner = double('provisioner')

    expect(RakeDocker::Container::Provisioner)
        .to(receive(:new)
            .with(
                container_name,
                image,
                ports: ports,
                environment: environment,
                reporter: reporter,
                ready?: ready_check
            )
            .and_return(provisioner))
    expect(provisioner).to(receive(:execute))

    subject.define(
        container_name: container_name,
        image: image,
        ports: ports,
        environment: environment,
        reporter: reporter,
        ready_check: ready_check)

    rake_task = Rake::Task["provision"]

    rake_task.invoke
  end

  def stub_provisioner
    provisioner = double('provisioner')
    allow(RakeDocker::Container::Provisioner)
        .to(receive(:new).and_return(provisioner))
    allow(provisioner).to(receive(:execute))
  end

  def stub_puts
    allow_any_instance_of(Kernel).to(receive(:puts))
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end
end
