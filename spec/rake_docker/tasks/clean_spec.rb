require 'spec_helper'
require 'fileutils'

describe RakeDocker::Tasks::Clean do
  include_context :rake

  it 'adds a clean task in the namespace in which it is created' do
    namespace :image do
      subject.define(
          image_name: 'nginx',
          work_directory: 'build')
    end

    expect(Rake::Task.task_defined?('image:clean')).to(be(true))
  end

  it 'gives the clean task a description' do
    namespace :image do
      subject.define(
          image_name: 'nginx',
          work_directory: 'build')
    end

    expect(Rake::Task["image:clean"].full_comment)
        .to(eq('Clean nginx image directory'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.define(
          name: :tidy_up,
          image_name: 'nginx',
          work_directory: 'build')
    end

    expect(Rake::Task.task_defined?('image:tidy_up')).to(be(true))
  end

  it 'allows multiple clean tasks to be declared' do
    namespace :image1 do
      subject.define(
          image_name: 'image1',
          work_directory: 'build')
    end

    namespace :image2 do
      subject.define(
          image_name: 'image2',
          work_directory: 'build')
    end

    expect(Rake::Task.task_defined?('image1:clean')).to(be(true))
    expect(Rake::Task.task_defined?('image2:clean')).to(be(true))
  end

  it 'recursively removes the image build path' do
    subject.define(
        image_name: 'nginx',
        work_directory: 'build')

    expect_any_instance_of(subject).to(receive(:rm_rf).with('build/nginx'))

    Rake::Task['clean'].invoke
  end

  it 'fails if no image name is provided' do
    subject.define(work_directory: 'build')

    allow(subject).to(receive(:rm_rf))

    expect {
      Rake::Task["clean"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no work directory is provided' do
    subject.define(image_name: 'nginx')

    allow(subject).to(receive(:rm_rf))

    expect {
      Rake::Task["clean"].invoke
    }.to raise_error(RakeFactory::RequiredParameterUnset)
  end
end
