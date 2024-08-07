# frozen_string_literal: true

require 'docker'
require 'json'

module RakeDocker
  module Container
    REPORTER_MESSAGES = %i[
      checking_if_container_exists
      container_exists
      container_does_not_exist
      checking_if_image_available
      image_available
      image_not_available
      pulling_image
      image_pulled
      creating_container
      container_created
      checking_if_container_running
      container_running
      container_not_running
      starting_container
      container_started
      waiting_for_container_to_be_ready
      container_ready
      stopping_container
      container_stopped
      deleting_container
      container_deleted
      done
    ].freeze

    class NullReporter
      REPORTER_MESSAGES.each do |message|
        define_method(message, proc { |*_| })
      end
    end

    class PrintingReporter
      def checking_if_container_exists(name)
        puts "Checking to see if #{name} exists..."
      end

      def container_exists(container)
        print "#{container.name} exists. "
      end

      def container_does_not_exist(name)
        puts "#{name} does not exist. Continuing."
      end

      def checking_if_image_available(image)
        puts "Checking if image #{image} is available locally..."
      end

      def image_available(image)
        puts "Image #{image} available. Continuing."
      end

      def image_not_available(image)
        print "Image #{image} not found. "
      end

      def pulling_image(_)
        puts 'Pulling.'
      end

      def image_pulled(image)
        puts "Image #{image} pulled. Continuing."
      end

      def creating_container(name, image)
        puts "Creating #{name} container from image #{image}..."
      end

      def container_created(container)
        print "#{container.name} created with ID: #{container.id}. "
      end

      def checking_if_container_running(_)
        puts 'Checking to see if it is running...'
      end

      def container_running(_)
        puts 'Container is running. Continuing.'
      end

      def container_not_running(_)
        print 'Container is not running. '
      end

      def starting_container(_)
        puts 'Starting...'
      end

      def container_started(_)
        puts 'Container started. Continuing.'
      end

      def waiting_for_container_to_be_ready(_)
        puts 'Waiting for container to be ready...'
      end

      def container_ready(_)
        puts 'Container ready. Continuing.'
      end

      def stopping_container(_)
        puts 'Stopping...'
      end

      def container_stopped(container)
        print "#{container.name} stopped. "
      end

      def deleting_container(_)
        puts 'Deleting...'
      end

      def container_deleted(container)
        puts "#{container.name} deleted."
      end

      def done
        puts 'Done.'
      end
    end

    module Utilities
      def find_container(name)
        enhance_with_name(Docker::Container.get(name), name)
      rescue Docker::Error::NotFoundError
        nil
      end

      def enhance_with_name(container, name)
        container.instance_eval do
          define_singleton_method(:name) { name }
        end
        container
      end
    end

    # rubocop:disable Metrics/ClassLength
    class Provisioner
      include Utilities

      attr_reader :name, :image, :ports, :environment, :ready, :reporter

      def initialize(name, image, opts = {})
        @name = name
        @image = image
        @environment = opts[:environment] || {}
        @ports = opts[:ports] || []
        @ready = opts[:ready?]
        @reporter = opts[:reporter] || NullReporter.new
      end

      # rubocop:disable Metrics/AbcSize
      def execute
        reporter.checking_if_container_exists(name)
        container = find_container(name)
        if container
          reporter.container_exists(container)
          ensure_container_running(container)
        else
          reporter.container_does_not_exist(name)
          start_new_container(name, image, ports, environment)
        end
        reporter.done
      end
      # rubocop:enable Metrics/AbcSize

      private

      def start_new_container(name, image, ports, environment)
        ensure_image_available(image)
        create_and_start_container(name, image, ports, environment)
      end

      def ensure_image_available(image)
        reporter.checking_if_image_available(image)
        matching_images = Docker::Image.all(filters: filters(image))
        if matching_images.empty?
          reporter.image_not_available(image)
          pull_image(image)
        else
          reporter.image_available(image)
        end
      end

      def pull_image(image)
        reporter.pulling_image(image)
        Docker::Image.create(fromImage: image)
        reporter.image_pulled(image)
      end

      def ensure_container_running(container)
        reporter.checking_if_container_running(container)
        container = find_container(name)
        if container_running?(container)
          reporter.container_running(container)
        else
          reporter.container_not_running(container)
          start_container(container)
        end
      end

      def create_and_start_container(name, image, ports, environment)
        start_container(create_container(image, name, ports, environment))
      end

      def create_container(image, name, ports, environment)
        exposed_ports, port_bindings = process_ports(ports)
        reporter.creating_container(name, image)
        container = Docker::Container.create(
          make_container_options(
            name, image, exposed_ports, port_bindings, environment
          )
        )
        container = enhance_with_name(container, name)
        reporter.container_created(container)
        container
      end

      def make_container_options(
        name, image, exposed_ports, port_bindings, environment
      )
        {
          name:,
          Image: image,
          ExposedPorts: exposed_ports,
          HostConfig: { PortBindings: port_bindings },
          Env: environment
        }
      end

      def start_container(container)
        reporter.starting_container(container)
        container.start
        reporter.container_started(container)
        if ready.respond_to?(:call)
          reporter.waiting_for_container_to_be_ready(container)
          ready.call(container)
          reporter.container_ready(container)
        end
        container
      end

      def container_running?(container)
        container_status(container) == 'running'
      end

      def container_status(container)
        container.json['State']['Status']
      end

      def process_ports(ports)
        port_config = ports.each_with_object(
          { exposed_ports: {}, port_bindings: {} }
        ) do |port, accumulator|
          host_port, container_port = port.split(':')
          accumulator[:exposed_ports]["#{container_port}/tcp"] = {}
          accumulator[:port_bindings]["#{container_port}/tcp"] =
            [{ HostPort: host_port }]
        end
        [port_config[:exposed_ports], port_config[:port_bindings]]
      end
    end
    # rubocop:enable Metrics/ClassLength

    class Destroyer
      include Utilities

      attr_reader :name, :reporter

      def initialize(name, opts = {})
        @name = name
        @reporter = opts[:reporter] || NullReporter.new
      end

      def execute
        reporter.checking_if_container_exists(name)
        container = find_container(name)
        if container
          reporter.container_exists(container)
          destroy_container(container)
        else
          reporter.container_does_not_exist(name)
        end
        reporter.done
      end

      private

      def destroy_container(container)
        reporter.stopping_container(container)
        container.stop
        container.wait
        reporter.container_stopped(container)
        reporter.deleting_container(container)
        container.delete
        reporter.container_deleted(container)
      end
    end
  end
end

def filters(image)
  JSON.generate(
    {
      reference: [image]
    }
  )
end
