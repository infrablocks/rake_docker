# frozen_string_literal: true

require 'spec_helper'

describe RakeDocker::Tasks::Destroy do
  include_context 'rake'

  before do
    stub_puts
  end

  it 'adds a destroy task in the namespace in which it is created' do
    namespace :container do
      described_class.define(container_name: 'web-server')
    end

    expect(Rake.application)
      .to(have_task_defined('container:destroy'))
  end

  it 'gives the destroy task a description' do
    namespace :container do
      described_class.define(container_name: 'web-server')
    end

    expect(Rake::Task['container:destroy'].full_comment)
      .to(eq('Destroy web-server container.'))
  end

  it 'allows the task name to be overridden' do
    namespace :container do
      described_class.define(
        name: :stop,
        container_name: 'web-server'
      )
    end

    expect(Rake.application)
      .to(have_task_defined('container:stop'))
  end

  it 'allows multiple provision tasks to be declared' do
    namespace :container1 do
      described_class.define(container_name: 'web-server-1')
    end

    namespace :container2 do
      described_class.define(container_name: 'web-server-2')
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[container1:destroy
               container2:destroy]
          ))
  end

  it 'fails if no container name is provided' do
    described_class.define

    stub_destroyer

    expect do
      Rake::Task['destroy'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates and executes a destroyer on invocation' do
    container_name = 'web-server'
    reporter = RakeDocker::Container::NullReporter.new

    destroyer = instance_double(RakeDocker::Container::Destroyer)

    allow(RakeDocker::Container::Destroyer)
      .to(receive(:new).and_return(destroyer))
    allow(destroyer)
      .to(receive(:execute))

    described_class.define(
      container_name:,
      reporter:
    )

    task = Rake::Task['destroy']

    task.invoke

    expect(RakeDocker::Container::Destroyer)
      .to(have_received(:new)
            .with(
              container_name,
              reporter:
            ))
    expect(destroyer).to(have_received(:execute))
  end
  # rubocop:enable RSpec/MultipleExpectations

  def stub_destroyer
    destroyer = instance_double(RakeDocker::Container::Destroyer)
    allow(RakeDocker::Container::Destroyer)
      .to(receive(:new).and_return(destroyer))
    allow(destroyer).to(receive(:execute))
  end

  def stub_puts
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end
end
