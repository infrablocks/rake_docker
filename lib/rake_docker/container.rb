module RakeDocker
  class Container
    attr_reader :name, :image, :ports, :environment, :ready, :reporter

    def initialize(name, image, opts = {})
      @name = name
      @image = image
      @environment = opts[:environment] || {}
      @ports = opts[:ports] || []
      @ready = opts[:ready?]
      @reporter = opts[:reporter] || NullReporter.new
    end

    def provision
      reporter.checking_if_container_exists(name)
      container = find_container(name)
      if container
        reporter.container_exists(container)
        ensure_container_running(container)
      else
        reporter.container_does_not_exist(name)
        ensure_image_available(image)
        create_and_start_container(name, image, ports, environment)
      end
      reporter.done
    end

    REPORTER_MESSAGES = [
        :checking_if_container_exists,
        :container_exists,
        :container_does_not_exist,
        :checking_if_image_available,
        :image_available,
        :image_not_available,
        :pulling_image,
        :image_pulled,
        :creating_container,
        :container_created,
        :checking_if_container_running,
        :container_running,
        :container_not_running,
        :starting_container,
        :container_started,
        :waiting_for_container_to_be_ready,
        :container_ready,
        :done
    ]

    class NullReporter
      REPORTER_MESSAGES.each { |message| define_method(message) {} }
    end

    private

    def find_container(name)
      begin
        Docker::Container.get(name)
      rescue Docker::Error::NotFoundError
        nil
      end
    end

    def ensure_image_available(image)
      reporter.checking_if_image_available(image)
      matching_images = Docker::Image.all(filter: image)
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
      container = Docker::Container.get(name)
      if !container_running?(container)
        reporter.container_not_running(container)
        start_container(container)
      else
        reporter.container_running(container)
      end
    end

    def create_and_start_container(name, image, ports, environment)
      start_container(create_container(image, name, ports, environment))
    end

    def create_container(image, name, ports, environment)
      exposed_ports, port_bindings = process_ports(ports)
      reporter.creating_container(name, image)
      container = Docker::Container.create(
          name: name,
          Image: image,
          ExposedPorts: exposed_ports,
          HostConfig: {
            PortBindings: port_bindings
          },
          Env: environment)
      reporter.container_created(container)
      container
    end

    def start_container(container)
      reporter.starting_container(container)
      container.start
      reporter.container_started(container)
      if ready && ready.respond_to?(:call)
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
      port_config = ports.reduce({
          exposed_ports: {},
          port_bindings: {}
      }) do |accumulator, port|
        host_port, container_port = port.split(':')
        accumulator[:exposed_ports]["#{container_port}/tcp"] = {}
        accumulator[:port_bindings]["#{container_port}/tcp"] =
            [{:'HostPort' => host_port}]
        accumulator
      end
      [port_config[:exposed_ports], port_config[:port_bindings]]
    end
  end
end
