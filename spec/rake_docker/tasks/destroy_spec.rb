require 'spec_helper'

describe RakeDocker::Tasks::Destroy do
  include_context :rake

  before(:each) do
    stub_puts
  end

  it 'adds a destroy task in the namespace in which it is created' do
    namespace :container do
      subject.define(container_name: 'web-server')
    end

    expect(Rake::Task.task_defined?('container:destroy')).to(be(true))
  end

  it 'gives the destroy task a description' do
    namespace :container do
      subject.define(container_name: 'web-server')
    end

    expect(Rake::Task["container:destroy"].full_comment)
        .to(eq('Destroy web-server container.'))
  end

  it 'allows the task name to be overridden' do
    namespace :container do
      subject.define(
          name: :stop,
          container_name: 'web-server')
    end

    expect(Rake::Task.task_defined?('container:stop')).to(be(true))
  end

  it 'allows multiple provision tasks to be declared' do
    namespace :container_1 do
      subject.define(container_name: 'web-server-1')
    end

    namespace :container_2 do
      subject.define(container_name: 'web-server-2')
    end

    expect(Rake::Task.task_defined?('container_1:destroy')).to(be(true))
    expect(Rake::Task.task_defined?('container_2:destroy')).to(be(true))
  end

  it 'fails if no container name is provided' do
    subject.define

    stub_destroyer

    expect {
      Rake::Task["destroy"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'creates and executes a destroyer on invocation' do
    container_name = "web-server"
    reporter = RakeDocker::Container::NullReporter.new

    destroyer = double('destroyer')

    expect(RakeDocker::Container::Destroyer)
        .to(receive(:new)
            .with(
                container_name,
                reporter: reporter
            )
            .and_return(destroyer))
    expect(destroyer).to(receive(:execute))

    subject.define(
        container_name: container_name,
        reporter: reporter)

    rake_task = Rake::Task["destroy"]

    rake_task.invoke
  end

  def stub_destroyer
    destroyer = double('destroyer')
    allow(RakeDocker::Container::Destroyer)
        .to(receive(:new).and_return(destroyer))
    allow(destroyer).to(receive(:execute))
  end

  def stub_puts
    allow_any_instance_of(Kernel).to(receive(:puts))
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end
end
