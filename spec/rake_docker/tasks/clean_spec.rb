# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe RakeDocker::Tasks::Clean do
  include_context 'rake'

  it 'adds a clean task in the namespace in which it is created' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build'
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:clean'))
  end

  it 'gives the clean task a description' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build'
      )
    end

    expect(Rake::Task['image:clean'].full_comment)
      .to(eq('Clean nginx image directory'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      described_class.define(
        name: :tidy_up,
        image_name: 'nginx',
        work_directory: 'build'
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:tidy_up'))
  end

  it 'allows multiple clean tasks to be declared' do
    namespace :image1 do
      described_class.define(
        image_name: 'image1',
        work_directory: 'build'
      )
    end

    namespace :image2 do
      described_class.define(
        image_name: 'image2',
        work_directory: 'build'
      )
    end

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[image1:clean
               image2:clean]
          ))
  end

  it 'recursively removes the image build path' do
    described_class.define(
      image_name: 'nginx',
      work_directory: 'build'
    )

    task = Rake::Task['clean']

    allow(task.creator).to(receive(:rm_rf))

    task.invoke

    expect(task.creator)
      .to(have_received(:rm_rf)
            .with('build/nginx'))
  end

  it 'fails if no image name is provided' do
    described_class.define(work_directory: 'build')

    task = Rake::Task['clean']

    allow(task.creator).to(receive(:rm_rf))

    expect do
      task.invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no work directory is provided' do
    described_class.define(image_name: 'nginx')

    task = Rake::Task['clean']

    allow(task.creator).to(receive(:rm_rf))

    expect do
      task.invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end
end
