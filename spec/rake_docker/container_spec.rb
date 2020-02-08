require 'spec_helper'
require 'docker'

describe RakeDocker::Container do
  context RakeDocker::Container::Provisioner do
    it 'does nothing when container is already running' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_container = MockDockerContainer.running(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_return(underlying_container))
      expect(underlying_container).not_to(receive(:start))
      expect(Docker::Image).not_to(receive(:create))
      expect(Docker::Container).not_to(receive(:create))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
          .new(name, image, reporter: reporter)

      provisioner.execute

      expect(reporter.messages)
          .to(eq([
              [:checking_if_container_exists, [name]],
              [:container_exists, [underlying_container]],
              [:checking_if_container_running, [underlying_container]],
              [:container_running, [underlying_container]],
              [:done, []]
          ]))
    end

    it 'starts an existing container if it is stopped' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_container = MockDockerContainer.exited(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_return(underlying_container))
      expect(underlying_container).to(receive(:start))
      expect(Docker::Image).not_to(receive(:create))
      expect(Docker::Container).not_to(receive(:create))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
          .new(name, image, reporter: reporter)

      provisioner.execute

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

    it 'creates and starts a container if none exists and image present' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_image = double(image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
          .to(receive(:all).with(filter: image)
              .and_return([underlying_image]))
      expect(Docker::Image).not_to(receive(:create))
      expect(Docker::Container)
          .to(receive(:create)
              .with(
                  hash_including(
                      name: name,
                      Image: image))
              .and_return(underlying_container))
      expect(underlying_container).to(receive(:start))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
          .new(name, image, reporter: reporter)

      provisioner.execute

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

    it 'fetches the image, creates and starts a container if none exists ' +
        'and image not present' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
          .to(receive(:all).with(filter: image)
              .and_return([]))
      expect(Docker::Image)
          .to(receive(:create)
              .with(fromImage: image))
      expect(Docker::Container)
          .to(receive(:create)
              .with(
                  hash_including(
                      name: name,
                      Image: image))
              .and_return(underlying_container))
      expect(underlying_container).to(receive(:start))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
          .new(name, image, reporter: reporter)

      provisioner.execute

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

    it 'passes the provided environment when creating the container' do
      name = 'my-container'
      image = 'nginx:latest'
      environment = {
          'THING_ONE' => 1,
          'THING_TWO' => 2,
      }
      underlying_image = double(image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
          .to(receive(:all).with(filter: image)
              .and_return([underlying_image]))
      allow(underlying_container).to(receive(:start))

      expect(Docker::Container)
          .to(receive(:create)
              .with(
                  hash_including(
                      Env: environment))
              .and_return(underlying_container))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
          .new(
              name, image,
              reporter: reporter,
              environment: environment)

      provisioner.execute
    end

    it 'configures the provided port mappings when creating the container' do
      name = 'my-container'
      image = 'nginx:latest'
      ports = ['5432:5678', '8080:80']
      underlying_image = double(image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
          .to(receive(:all).with(filter: image)
              .and_return([underlying_image]))
      allow(underlying_container).to(receive(:start))

      expect(Docker::Container)
          .to(receive(:create)
              .with(
                  hash_including(
                      ExposedPorts: {'5678/tcp' => {}, '80/tcp' => {}},
                      HostConfig: {
                          PortBindings: {
                              '5678/tcp' => [{HostPort: '5432'}],
                              '80/tcp' => [{HostPort: '8080'}]}
                      }))
              .and_return(underlying_container))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
          .new(
              name, image,
              reporter: reporter,
              ports: ports)

      provisioner.execute
    end

    it 'calls the supplied readiness poller when provided' do
      name = 'my-container'
      image = 'nginx:latest'
      ready_calls = []
      ready = lambda do |arg|
        ready_calls << [arg]
        true
      end

      underlying_image = double(image)
      underlying_container = MockDockerContainer.created(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_raise(Docker::Error::NotFoundError))
      allow(Docker::Image)
          .to(receive(:all).with(filter: image)
              .and_return([underlying_image]))
      allow(Docker::Container)
          .to(receive(:create)
              .and_return(underlying_container))
      allow(underlying_container).to(receive(:start))

      reporter = MockReporter.new
      provisioner = RakeDocker::Container::Provisioner
          .new(
              name, image,
              reporter: reporter,
              ready?: ready)

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

  context RakeDocker::Container::Destroyer do
    it 'does nothing when the container does not exist' do
      name = 'my-container'
      image = 'nginx:latest'

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_raise(Docker::Error::NotFoundError))

      reporter = MockReporter.new
      destroyer = RakeDocker::Container::Destroyer
          .new(name, reporter: reporter)

      destroyer.execute

      expect(reporter.messages)
          .to(eq([
              [:checking_if_container_exists, [name]],
              [:container_does_not_exist, [name]],
              [:done, []]
          ]))
    end

    it 'stops and deletes the container when the container exists' do
      name = 'my-container'
      image = 'nginx:latest'
      underlying_container = MockDockerContainer.running(name)

      allow(Docker::Container)
          .to(receive(:get).with(name)
              .and_return(underlying_container))

      expect(underlying_container).to(receive(:stop).ordered)
      expect(underlying_container).to(receive(:delete).ordered)

      reporter = MockReporter.new
      destroyer = RakeDocker::Container::Destroyer
          .new(name, reporter: reporter)

      destroyer.execute

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
    {'State' => {'Status' => status}}
  end
end
