require 'spec_helper'
require 'fileutils'

describe RakeDocker::Tasks::Clean do
  include_context :rake

  it 'adds a clean task in the namespace in which it is created' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.work_directory = 'build'
      end
    end

    expect(Rake::Task['image:clean']).not_to be_nil
  end

  it 'gives the clean task a description' do
    namespace :image do
      subject.new do |t|
        t.image_name = 'nginx'
        t.work_directory = 'build'
      end
    end

    expect(rake.last_description).to(eq('Clean nginx image directory'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.new(:tidy_up) do |t|
        t.image_name = 'nginx'
        t.work_directory = 'build'
      end
    end

    expect(Rake::Task['image:tidy_up']).not_to be_nil
  end

  it 'allows multiple clean tasks to be declared' do
    namespace :image1 do
      subject.new do |t|
        t.image_name = 'image1'
        t.work_directory = 'build'
      end
    end

    namespace :image2 do
      subject.new do |t|
        t.image_name = 'image2'
        t.work_directory = 'build'
      end
    end

    image1_clean = Rake::Task['image1:clean']
    image2_clean = Rake::Task['image2:clean']

    expect(image1_clean).not_to be_nil
    expect(image2_clean).not_to be_nil
  end

  it 'recursively removes the image build path' do
    subject.new do |t|
      t.image_name = 'nginx'
      t.work_directory = 'build'
    end

    expect_any_instance_of(subject).to(receive(:rm_rf).with('build/nginx'))

    Rake::Task['clean'].invoke
  end

  it 'fails if no image name is provided' do
    expect {
      subject.new do |t|
        t.work_directory = 'build'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'fails if no work directory is provided' do
    expect {
      subject.new do |t|
        t.image_name = 'nginx'
      end
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end
end
