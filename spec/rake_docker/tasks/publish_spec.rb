# frozen_string_literal: true

require 'spec_helper'

describe RakeDocker::Tasks::Publish do
  include_context 'rake'

  it 'adds a publish task in the namespace in which it is created' do
    namespace :image do
      described_class.define
    end

    expect(Rake.application)
      .to(have_task_defined('image:publish'))
  end

  it 'gives the publish task a description' do
    namespace :image do
      described_class.define(image_name: 'nginx')
    end

    expect(Rake::Task['image:publish'].full_comment)
      .to(eq('Publish nginx image'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      described_class.define(name: :build_and_push)
    end

    expect(Rake.application)
      .to(have_task_defined('image:build_and_push'))
  end

  it 'allows multiple publish tasks to be declared' do
    namespace :image1 do
      described_class.define
    end

    namespace :image2 do
      described_class.define
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[image1:publish
               image2:publish]
          ))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'invokes other tasks with arguments in order' do
    clean_task_stub = instance_double(Rake::Task, 'clean')
    build_task_stub = instance_double(Rake::Task, 'build')
    tag_task_stub = instance_double(Rake::Task, 'tag')
    push_task_stub = instance_double(Rake::Task, 'push')

    arguments = %w[first second]

    namespace :image do
      described_class.define(argument_names: %i[thing1 thing2])
    end

    rake_task = Rake::Task['image:publish']

    allow(clean_task_stub).to(receive(:invoke))
    allow(build_task_stub).to(receive(:invoke))
    allow(tag_task_stub).to(receive(:invoke))
    allow(push_task_stub).to(receive(:invoke))

    allow(Rake::Task)
      .to(receive(:[]).with('image:clean')
            .and_return(clean_task_stub))
    allow(Rake::Task)
      .to(receive(:[]).with('image:build')
            .and_return(build_task_stub))
    allow(Rake::Task)
      .to(receive(:[]).with('image:tag')
            .and_return(tag_task_stub))
    allow(Rake::Task)
      .to(receive(:[]).with('image:push')
            .and_return(push_task_stub))

    rake_task.invoke(*arguments)

    expect(clean_task_stub)
      .to(have_received(:invoke).with(*arguments).ordered)
    expect(build_task_stub)
      .to(have_received(:invoke).with(*arguments).ordered)
    expect(tag_task_stub)
      .to(have_received(:invoke).with(*arguments).ordered)
    expect(push_task_stub)
      .to(have_received(:invoke).with(*arguments).ordered)
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'allows clean task name to be overridden' do
    clean_task_stub = instance_double(Rake::Task, 'clean')
    other_task_stub = instance_double(Rake::Task, 'other')

    arguments = %w[first second]

    namespace :image do
      described_class.define(
        clean_task_name: :clean_it,
        argument_names: %i[thing1 thing2]
      )
    end

    rake_task = Rake::Task['image:publish']

    allow(clean_task_stub).to(receive(:invoke))
    allow(other_task_stub).to(receive(:invoke))

    allow(Rake::Task)
      .to(receive(:[]))
      .and_return(other_task_stub)
    allow(Rake::Task)
      .to(receive(:[]).with('image:clean_it')
            .and_return(clean_task_stub))

    rake_task.invoke(*arguments)

    expect(clean_task_stub)
      .to(have_received(:invoke).with(*arguments))
    expect(other_task_stub)
      .to(have_received(:invoke).exactly(3).times)
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'allows build task name to be overridden' do
    build_task_stub = instance_double(Rake::Task, 'build')
    other_task_stub = instance_double(Rake::Task, 'other')

    arguments = %w[first second]

    namespace :image do
      described_class.define(
        build_task_name: :build_it,
        argument_names: %i[thing1 thing2]
      )
    end

    rake_task = Rake::Task['image:publish']

    allow(build_task_stub).to(receive(:invoke))
    allow(other_task_stub).to(receive(:invoke))

    allow(Rake::Task)
      .to(receive(:[]))
      .and_return(other_task_stub)
    allow(Rake::Task)
      .to(receive(:[]).with('image:build_it')
            .and_return(build_task_stub))

    rake_task.invoke(*arguments)

    expect(build_task_stub)
      .to(have_received(:invoke)
            .with(*arguments))
    expect(other_task_stub)
      .to(have_received(:invoke).exactly(3).times)
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'allows tag task name to be overridden' do
    tag_task_stub = instance_double(Rake::Task, 'tag')
    other_task_stub = instance_double(Rake::Task, 'other')

    arguments = %w[first second]

    namespace :image do
      described_class.define(
        tag_task_name: :tag_it,
        argument_names: %i[thing1 thing2]
      )
    end

    rake_task = Rake::Task['image:publish']

    allow(tag_task_stub).to(receive(:invoke))
    allow(other_task_stub).to(receive(:invoke))

    allow(Rake::Task)
      .to(receive(:[]))
      .and_return(other_task_stub)
    allow(Rake::Task)
      .to(receive(:[]).with('image:tag_it')
            .and_return(tag_task_stub))

    rake_task.invoke(*arguments)

    expect(tag_task_stub)
      .to(have_received(:invoke).with(*arguments))
    expect(other_task_stub)
      .to(have_received(:invoke).exactly(3).times)
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'allows push task name to be overridden' do
    push_task_stub = instance_double(Rake::Task, 'push')
    other_task_stub = instance_double(Rake::Task, 'other')

    arguments = %w[first second]

    namespace :image do
      described_class.define(
        push_task_name: :push_it,
        argument_names: %i[thing1 thing2]
      )
    end

    rake_task = Rake::Task['image:publish']

    allow(push_task_stub).to(receive(:invoke))
    allow(other_task_stub).to(receive(:invoke))

    allow(Rake::Task)
      .to(receive(:[]))
      .and_return(other_task_stub)
    allow(Rake::Task)
      .to(receive(:[]).with('image:push_it')
            .and_return(push_task_stub))

    rake_task.invoke(*arguments)

    expect(push_task_stub)
      .to(have_received(:invoke)
            .with(*arguments))
    expect(other_task_stub)
      .to(have_received(:invoke).exactly(3).times)
  end
  # rubocop:enable RSpec/MultipleExpectations
end
