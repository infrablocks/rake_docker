# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe RakeDocker::TaskSets::Container do
  include_context 'rake'

  def define_tasks(opts = {}, &block)
    described_class.define({
      container_name: 'web-server',
      image: 'nginx:latest',
      ports: ['8080:80'],
      environment: {
        'THING1' => 'one',
        'THING2' => 'two'
      }
    }.merge(opts), &block)
  end

  it 'adds all container tasks in the provided namespace when supplied' do
    define_tasks(namespace: :some_container)

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[some_container:provision
               some_container:destroy]
          ))
  end

  it 'adds all container tasks in the root namespace when none supplied' do
    define_tasks

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[provision
               destroy]
          ))
  end

  describe 'provision task' do
    it 'configures with the provided container name' do
      container_name = 'database'

      define_tasks(
        container_name:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.container_name).to(eq(container_name))
    end

    it 'configures with the provided image' do
      image = 'mysql:5.6'

      define_tasks(
        image:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.image).to(eq(image))
    end

    it 'configures with the provided ports' do
      ports = ['3306:3306']

      define_tasks(
        ports:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.ports).to(eq(ports))
    end

    it 'configures with the provided environment' do
      environment = { 'MYSQL_USERNAME' => 'db_admin' }

      define_tasks(
        environment:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.environment).to(eq(environment))
    end

    it 'configures with the provided ready check' do
      ready_check = proc { true }

      define_tasks(
        ready_check:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.ready_check).to(eq(ready_check))
    end

    it 'configures with the provided reporter' do
      reporter = RakeDocker::Container::NullReporter.new

      define_tasks(
        reporter:
      )

      rake_task = Rake::Task['provision']

      expect(rake_task.creator.reporter).to(eq(reporter))
    end

    it 'uses a name of provision by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('provision'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(provision_task_name: :start)

      expect(Rake.application)
        .to(have_task_defined('start'))
    end
  end

  describe 'destroy task' do
    it 'configures with the provided container name' do
      container_name = 'database'

      define_tasks(
        container_name:
      )

      rake_task = Rake::Task['destroy']

      expect(rake_task.creator.container_name).to(eq(container_name))
    end

    it 'configures with the provided reporter' do
      reporter = RakeDocker::Container::NullReporter.new

      define_tasks(
        reporter:
      )

      rake_task = Rake::Task['destroy']

      expect(rake_task.creator.reporter).to(eq(reporter))
    end

    it 'uses a name of destroy by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('destroy'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(provision_task_name: :stop)

      expect(Rake.application)
        .to(have_task_defined('stop'))
    end
  end
end
