# frozen_string_literal: true

require 'spec_helper'

describe RakeDocker::Tasks::Provision do
  include_context 'rake'

  before do
    stub_puts
  end

  it 'adds a provision task in the namespace in which it is created' do
    namespace :container do
      described_class.define(
        container_name: 'web-server',
        image: 'nginx:latest'
      )
    end

    expect(Rake.application)
      .to(have_task_defined('container:provision'))
  end

  it 'gives the provision task a description' do
    namespace :container do
      described_class.define(
        container_name: 'web-server',
        image: 'nginx:latest'
      )
    end

    expect(Rake::Task['container:provision'].full_comment)
      .to(eq('Provision web-server container.'))
  end

  it 'allows the task name to be overridden' do
    namespace :container do
      described_class.define(
        name: :start,
        container_name: 'web-server',
        image: 'nginx:latest'
      )
    end

    expect(Rake.application)
      .to(have_task_defined('container:start'))
  end

  it 'allows multiple provision tasks to be declared' do
    namespace :container1 do
      described_class.define(
        container_name: 'web-server-1',
        image: 'nginx:latest'
      )
    end

    namespace :container2 do
      described_class.define(
        container_name: 'web-server-2',
        image: 'nginx:latest'
      )
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[container1:provision
               container2:provision]
          ))
  end

  it 'fails if no container name is provided' do
    described_class.define(image: 'nginx:latest')

    stub_provisioner

    expect do
      Rake::Task['provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no image is provided' do
    described_class.define(container_name: 'web-server')

    stub_provisioner

    expect do
      Rake::Task['provision'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates and executes a provisioner on invocation' do
    container_name = 'web-server'
    image = 'nginx:latest'
    ports = ['1234:1234']
    environment = {
      'THING1' => 'one',
      'THING2' => 'two'
    }
    command = ['ls', '-l']
    reporter = RakeDocker::Container::NullReporter.new
    ready_check = proc { true }

    provisioner = instance_double(RakeDocker::Container::Provisioner)

    allow(RakeDocker::Container::Provisioner)
      .to(receive(:new).and_return(provisioner))
    allow(provisioner).to(receive(:execute))

    described_class.define(
      container_name:,
      image:,
      ports:,
      environment:,
      command:,
      reporter:,
      ready_check:
    )

    rake_task = Rake::Task['provision']

    rake_task.invoke

    expect(RakeDocker::Container::Provisioner)
      .to(have_received(:new)
            .with(
              container_name,
              image,
              ports:,
              environment:,
              command:,
              reporter:,
              ready?: ready_check
            ))
    expect(provisioner).to(have_received(:execute))
  end
  # rubocop:enable RSpec/MultipleExpectations

  def stub_provisioner
    provisioner = instance_double(RakeDocker::Container::Provisioner)
    allow(RakeDocker::Container::Provisioner)
      .to(receive(:new).and_return(provisioner))
    allow(provisioner).to(receive(:execute))
  end

  def stub_puts
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end
end
