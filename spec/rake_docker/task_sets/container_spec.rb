require 'spec_helper'
require 'fileutils'

describe RakeDocker::TaskSets::Container do
  include_context :rake

  def define_tasks(opts = {}, &block)
    subject.define({
        container_name: 'web-server',
        image: 'nginx:latest',
        ports: ["8080:80"],
        environment: {
            "THING1" => "one",
            "THING2" => "two"
        },
    }.merge(opts), &block)
  end

  it 'adds all container tasks in the provided namespace when supplied' do
    define_tasks(namespace: :some_container)

    expect(Rake::Task.task_defined?('some_container:provision')).to(be(true))
    expect(Rake::Task.task_defined?('some_container:destroy')).to(be(true))
  end

  it 'adds all container tasks in the root namespace when none supplied' do
    define_tasks

    expect(Rake::Task.task_defined?('provision')).to(be(true))
    expect(Rake::Task.task_defined?('destroy')).to(be(true))
  end

  context 'provision task' do
    it 'configures with the provided parameters' do
      container_name = 'database'
      image = "mysql:5.6"
      ports = ["3306:3306"]
      environment = {"MYSQL_USERNAME" => "db_admin"}
      ready_check = proc { true }
      reporter = RakeDocker::Container::NullReporter.new

      define_tasks(
          container_name: container_name,
          image: image,
          ports: ports,
          environment: environment,
          ready_check: ready_check,
          reporter: reporter)

      rake_task = Rake::Task["provision"]

      expect(rake_task.creator.container_name).to(eq(container_name))
      expect(rake_task.creator.image).to(eq(image))
      expect(rake_task.creator.ports).to(eq(ports))
      expect(rake_task.creator.environment).to(eq(environment))
      expect(rake_task.creator.ready_check).to(eq(ready_check))
      expect(rake_task.creator.reporter).to(eq(reporter))
    end

    it 'uses a name of provision by default' do
      define_tasks

      expect(Rake::Task.task_defined?("provision")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(provision_task_name: :start)

      expect(Rake::Task.task_defined?("start")).to(be(true))
    end
  end

  context 'destroy task' do
    it 'configures with the provided parameters' do
      container_name = 'database'
      image = "mysql:5.6"
      ports = ["3306:3306"]
      environment = {"MYSQL_USERNAME" => "db_admin"}
      ready_check = proc { true }
      reporter = RakeDocker::Container::NullReporter.new

      define_tasks(
          container_name: container_name,
          image: image,
          ports: ports,
          environment: environment,
          ready_check: ready_check,
          reporter: reporter)

      rake_task = Rake::Task["destroy"]

      expect(rake_task.creator.container_name).to(eq(container_name))
      expect(rake_task.creator.reporter).to(eq(reporter))
    end

    it 'uses a name of destroy by default' do
      define_tasks

      expect(Rake::Task.task_defined?("destroy")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(provision_task_name: :stop)

      expect(Rake::Task.task_defined?("stop")).to(be(true))
    end
  end
end
