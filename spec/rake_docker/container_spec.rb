# frozen_string_literal: true

require 'spec_helper'
require 'docker'
require 'json'

describe RakeDocker::Container do
  context RakeDocker::Container::Provisioner do
    # rubocop:disable RSpec/MultipleExpectations
    it 'does nothing when container is already running' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_container = MockDockerContainer.running(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_return(underlying_container))
      allow(underlying_container).to(receive(:start))
      allow(Docker::Image).to(receive(:create))
      allow(Docker::Container).to(receive(:create))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(name, image, reporter:)

      provisioner.execute

      expect(underlying_container)
        .not_to(have_received(:start))
      expect(Docker::Image)
        .not_to(have_received(:create))
      expect(Docker::Container)
        .not_to(have_received(:create))
      expect(reporter.messages)
        .to(eq([
                 [:checking_if_container_exists, [name]],
                 [:container_exists, [underlying_container]],
                 [:checking_if_container_running, [underlying_container]],
                 [:container_running, [underlying_container]],
                 [:done, []]
               ]))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'starts an existing container if it is stopped' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_container = MockDockerContainer.exited(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_return(underlying_container))
      allow(underlying_container).to(receive(:start))
      allow(Docker::Image).to(receive(:create))
      allow(Docker::Container).to(receive(:create))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(name, image, reporter:)

      provisioner.execute

      expect(underlying_container)
        .to(have_received(:start))
      expect(Docker::Image)
        .not_to(have_received(:create))
      expect(Docker::Container)
        .not_to(have_received(:create))
      expect(reporter.messages)
        .to(eq([
                 [:checking_if_container_exists, [name]],
                 [:container_exists, [underlying_container]],
                 [:checking_if_container_running, [underlying_container]],
                 [:container_not_running, [underlying_container]],
                 [:starting_container, [underlying_container]],
                 [:container_started, [underlying_container]],
                 [:done, []]
               ]))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'creates and starts a container if none exists and image present' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_image = instance_double(Docker::Image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
        .to(receive(:all).with(filters: filters(image))
                         .and_return([underlying_image]))
      allow(Docker::Image).to(receive(:create))
      allow(Docker::Container)
        .to(receive(:create)
              .and_return(underlying_container))
      allow(underlying_container).to(receive(:start))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(name, image, reporter:)

      provisioner.execute

      expect(Docker::Image).not_to(have_received(:create))
      expect(Docker::Container)
        .to(have_received(:create)
              .with(hash_including(name:, Image: image)))
      expect(underlying_container).to(have_received(:start))
      expect(reporter.messages)
        .to(eq([
                 [:checking_if_container_exists, [name]],
                 [:container_does_not_exist, [name]],
                 [:checking_if_image_available, [image]],
                 [:image_available, [image]],
                 [:creating_container, [name, image]],
                 [:container_created, [underlying_container]],
                 [:starting_container, [underlying_container]],
                 [:container_started, [underlying_container]],
                 [:done, []]
               ]))
    end
    # rubocop:enable RSpec/MultipleExpectations

    # rubocop:disable RSpec/MultipleExpectations
    it 'fetches the image, creates and starts a container if none exists ' \
       'and image not present' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
        .to(receive(:all).with(filters: filters(image))
                         .and_return([]))
      allow(Docker::Image)
        .to(receive(:create).with(fromImage: image))
      allow(Docker::Container)
        .to(receive(:create)
              .and_return(underlying_container))
      allow(underlying_container).to(receive(:start))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(name, image, reporter:)

      provisioner.execute

      expect(Docker::Image)
        .to(have_received(:create).with(fromImage: image))
      expect(Docker::Container)
        .to(have_received(:create)
              .with(hash_including(name:, Image: image)))
      expect(underlying_container)
        .to(have_received(:start))
      expect(reporter.messages)
        .to(eq([
                 [:checking_if_container_exists, [name]],
                 [:container_does_not_exist, [name]],
                 [:checking_if_image_available, [image]],
                 [:image_not_available, [image]],
                 [:pulling_image, [image]],
                 [:image_pulled, [image]],
                 [:creating_container, [name, image]],
                 [:container_created, [underlying_container]],
                 [:starting_container, [underlying_container]],
                 [:container_started, [underlying_container]],
                 [:done, []]
               ]))
    end
    # rubocop:enable RSpec/MultipleExpectations

    it 'passes the provided environment when creating the container' do
      name = 'my-container'
      image = 'nginx:latest'
      environment = {
        'THING_ONE' => 1,
        'THING_TWO' => 2
      }
      underlying_image = instance_double(Docker::Image, image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
        .to(receive(:all).with(filters: filters(image))
                         .and_return([underlying_image]))
      allow(underlying_container).to(receive(:start))
      allow(Docker::Container)
        .to(receive(:create)
              .and_return(underlying_container))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(
                      name, image,
                      reporter:,
                      environment:
                    )

      provisioner.execute

      expect(Docker::Container)
        .to(have_received(:create)
              .with(hash_including(Env: environment)))
    end

    it 'configures the provided port mappings when creating the container' do
      name = 'my-container'
      image = 'nginx:latest'
      ports = %w[5432:5678 8080:80]
      underlying_image = instance_double(Docker::Image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
        .to(receive(:all).with(filters: filters(image))
                         .and_return([underlying_image]))
      allow(underlying_container).to(receive(:start))

      allow(Docker::Container)
        .to(receive(:create).and_return(underlying_container))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(
                      name, image,
                      reporter:,
                      ports:
                    )

      provisioner.execute

      expect(Docker::Container)
        .to(have_received(:create)
              .with(
                hash_including(
                  ExposedPorts: { '5678/tcp' => {}, '80/tcp' => {} },
                  HostConfig: {
                    PortBindings: {
                      '5678/tcp' => [{ HostPort: '5432' }],
                      '80/tcp' => [{ HostPort: '8080' }]
                    }
                  }
                )
              ))
    end

    it 'passes the provided command when creating the container' do
      name = 'my-container'
      image = 'nginx:latest'
      command = ['ls', '-l']
      underlying_image = instance_double(Docker::Image, image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
        .to(receive(:all).with(filters: filters(image))
                         .and_return([underlying_image]))
      allow(underlying_container).to(receive(:start))
      allow(Docker::Container)
        .to(receive(:create)
              .and_return(underlying_container))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(
                      name, image,
                      reporter:,
                      command:
                    )

      provisioner.execute

      expect(Docker::Container)
        .to(have_received(:create)
              .with(hash_including(Cmd: command)))
    end

    it 'passes nil for the command when creating container with no command' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_image = instance_double(Docker::Image, image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
        .to(receive(:all).with(filters: filters(image))
                         .and_return([underlying_image]))
      allow(underlying_container).to(receive(:start))
      allow(Docker::Container)
        .to(receive(:create)
              .and_return(underlying_container))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(
                      name, image,
                      reporter:
                    )

      provisioner.execute

      expect(Docker::Container)
        .to(have_received(:create)
              .with(hash_including(Cmd: nil)))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'calls the supplied readiness poller when provided' do
      name = 'my-container'
      image = 'nginx:latest'
      ready_calls = []
      ready = lambda do |arg|
        ready_calls << [arg]
        true
      end

      underlying_image = instance_double(Docker::Image, image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
        .to(receive(:get)
              .with(name)
              .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
        .to(receive(:all)
              .with(filters: filters(image))
              .and_return([underlying_image]))
      allow(Docker::Container)
        .to(receive(:create)
              .and_return(underlying_container))
      allow(underlying_container).to(receive(:start))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
                    .new(name, image, reporter:, ready?: ready)

      provisioner.execute

      expect(ready_calls).to(eq([[underlying_container]]))
      expect(reporter.messages)
        .to(eq([
                 [:checking_if_container_exists, [name]],
                 [:container_does_not_exist, [name]],
                 [:checking_if_image_available, [image]],
                 [:image_available, [image]],
                 [:creating_container, [name, image]],
                 [:container_created, [underlying_container]],
                 [:starting_container, [underlying_container]],
                 [:container_started, [underlying_container]],
                 [:waiting_for_container_to_be_ready, [underlying_container]],
                 [:container_ready, [underlying_container]],
                 [:done, []]
               ]))
    end
  end
  # rubocop:enable RSpec/MultipleExpectations

  context RakeDocker::Container::Destroyer do
    it 'does nothing when the container does not exist' do
      name = 'my-container'

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_raise(Docker::Error::NotFoundError))

      reporter = MockReporter.new
      destroyer = RakeDocker::Container::Destroyer
                  .new(name, reporter:)

      destroyer.execute

      expect(reporter.messages)
        .to(eq([
                 [:checking_if_container_exists, [name]],
                 [:container_does_not_exist, [name]],
                 [:done, []]
               ]))
    end

    # rubocop:disable RSpec/MultipleExpectations
    it 'stops and deletes the container when the container exists' do
      name = 'my-container'
      underlying_container = MockDockerContainer.running(name)

      allow(Docker::Container)
        .to(receive(:get).with(name)
                         .and_return(underlying_container))
      allow(underlying_container).to(receive(:stop))
      allow(underlying_container).to(receive(:wait))
      allow(underlying_container).to(receive(:delete))

      reporter = MockReporter.new
      destroyer = RakeDocker::Container::Destroyer
                  .new(name, reporter:)

      destroyer.execute

      expect(underlying_container)
        .to(have_received(:stop).ordered)
      expect(underlying_container)
        .to(have_received(:wait).ordered)
      expect(underlying_container)
        .to(have_received(:delete).ordered)
      expect(reporter.messages)
        .to(eq([
                 [:checking_if_container_exists, [name]],
                 [:container_exists, [underlying_container]],
                 [:stopping_container, [underlying_container]],
                 [:container_stopped, [underlying_container]],
                 [:deleting_container, [underlying_container]],
                 [:container_deleted, [underlying_container]],
                 [:done, []]
               ]))
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end

class MockReporter
  attr_reader :messages

  def initialize
    @messages = []
  end

  RakeDocker::Container::REPORTER_MESSAGES.each do |message|
    define_method message do |*args|
      @messages << [message, args]
    end
  end
end

class MockDockerContainer
  attr_accessor :name, :status

  def self.created(name)
    new(name, 'created')
  end

  def self.running(name)
    new(name, 'running')
  end

  def self.exited(name)
    new(name, 'exited')
  end

  def initialize(name, status)
    self.name = name
    self.status = status
  end

  def json
    { 'State' => { 'Status' => status } }
  end
end

def filters(image)
  JSON.generate(
    {
      reference: [image]
    }
  )
end
