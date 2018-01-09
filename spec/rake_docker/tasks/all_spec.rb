require 'spec_helper'
require 'fileutils'

describe RakeDocker::Tasks::All do
  include_context :rake

  it 'adds all tasks in the provided namespace when supplied' do
    define_tasks do |t|
      t.namespace = :some_image
    end

    expect(Rake::Task['some_image:clean']).not_to be_nil
    expect(Rake::Task['some_image:prepare']).not_to be_nil
    expect(Rake::Task['some_image:build']).not_to be_nil
    expect(Rake::Task['some_image:tag']).not_to be_nil
    expect(Rake::Task['some_image:push']).not_to be_nil
  end

  it 'adds all tasks in the root namespace when none supplied' do
    define_tasks do |t|
      t.namespace = nil
    end

    expect(Rake::Task['clean']).not_to be_nil
    expect(Rake::Task['prepare']).not_to be_nil
    expect(Rake::Task['build']).not_to be_nil
    expect(Rake::Task['tag']).not_to be_nil
    expect(Rake::Task['push']).not_to be_nil
  end

  context 'clean task' do
    it 'configures with the provided image name and work directory' do
      image_name = 'apache'
      work_directory = 'tmp'

      clean_configurer = stubbed_clean_configurer

      expect(RakeDocker::Tasks::Clean)
          .to(receive(:new).and_yield(clean_configurer))
      expect(clean_configurer).to(receive(:image_name=).with(image_name))
      expect(clean_configurer)
          .to(receive(:work_directory=).with(work_directory))

      define_tasks do |t|
        t.image_name = image_name
        t.work_directory = work_directory
      end
    end

    it 'uses a name of clean by default' do
      clean_configurer = stubbed_clean_configurer

      expect(RakeDocker::Tasks::Clean)
          .to(receive(:new).and_yield(clean_configurer))
      expect(clean_configurer).to(receive(:name=).with(:clean))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      clean_configurer = stubbed_clean_configurer

      expect(RakeDocker::Tasks::Clean)
          .to(receive(:new).and_yield(clean_configurer))
      expect(clean_configurer).to(receive(:name=).with(:clean_it_up))

      define_tasks do |t|
        t.clean_task_name = :clean_it_up
      end
    end
  end

  context 'prepare task' do
    it 'configures with the provided image name and work directory' do
      image_name = 'apache'
      work_directory = 'tmp'

      prepare_configurer = stubbed_prepare_configurer

      expect(RakeDocker::Tasks::Prepare)
          .to(receive(:new).and_yield(prepare_configurer))
      expect(prepare_configurer)
          .to(receive(:image_name=).with(image_name))
      expect(prepare_configurer)
          .to(receive(:work_directory=).with(work_directory))

      define_tasks do |t|
        t.image_name = image_name
        t.work_directory = work_directory
      end
    end

    it 'passes the default copy spec when none supplied' do
      prepare_configurer = stubbed_prepare_configurer

      expect(RakeDocker::Tasks::Prepare)
          .to(receive(:new).and_yield(prepare_configurer))
      expect(prepare_configurer)
          .to(receive(:copy_spec=).with([]))

      define_tasks
    end

    it 'passes the provided copy spec when supplied' do
      copy_spec = ['file1.txt', 'file2.rb']
      prepare_configurer = stubbed_prepare_configurer

      expect(RakeDocker::Tasks::Prepare)
          .to(receive(:new).and_yield(prepare_configurer))
      expect(prepare_configurer)
          .to(receive(:copy_spec=).with(copy_spec))

      define_tasks do |t|
        t.copy_spec = copy_spec
      end
    end

    it 'passes the default create spec when none supplied' do
      prepare_configurer = stubbed_prepare_configurer

      expect(RakeDocker::Tasks::Prepare)
          .to(receive(:new).and_yield(prepare_configurer))
      expect(prepare_configurer)
          .to(receive(:create_spec=).with([]))

      define_tasks
    end

    it 'passes the provided create spec when supplied' do
      create_spec = [
          {content: 'some-content', to: 'some-file.txt'}
      ]
      prepare_configurer = stubbed_prepare_configurer

      expect(RakeDocker::Tasks::Prepare)
          .to(receive(:new).and_yield(prepare_configurer))
      expect(prepare_configurer)
          .to(receive(:create_spec=).with(create_spec))

      define_tasks do |t|
        t.create_spec = create_spec
      end
    end

    it 'uses a name of prepare by default' do
      prepare_configurer = stubbed_prepare_configurer

      expect(RakeDocker::Tasks::Prepare)
          .to(receive(:new).and_yield(prepare_configurer))
      expect(prepare_configurer)
          .to(receive(:name=).with(:prepare))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      prepare_configurer = stubbed_prepare_configurer

      expect(RakeDocker::Tasks::Prepare)
          .to(receive(:new).and_yield(prepare_configurer))
      expect(prepare_configurer)
          .to(receive(:name=).with(:prepare_for_build))

      define_tasks do |t|
        t.prepare_task_name = :prepare_for_build
      end
    end
  end

  context 'build task' do
    it 'configures with the provided image name and work directory' do
      image_name = 'apache'
      repository_name = 'apache/apache'
      work_directory = 'tmp'

      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:image_name=).with(image_name))
      expect(build_configurer)
          .to(receive(:repository_name=).with(repository_name))
      expect(build_configurer)
          .to(receive(:work_directory=).with(work_directory))

      define_tasks do |t|
        t.image_name = image_name
        t.repository_name = repository_name
        t.work_directory = work_directory
      end
    end

    it 'uses a name of build by default' do
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:name=).with(:build))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:name=).with(:build_it_now))

      define_tasks do |t|
        t.build_task_name = :build_it_now
      end
    end

    it 'uses a prepare task name of prepare by default' do
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:prepare_task=).with(:prepare))

      define_tasks
    end

    it 'uses the provided prepare task name when supplied' do
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:prepare_task=).with(:prepare_it))

      define_tasks do |t|
        t.prepare_task_name = :prepare_it
      end
    end

    it 'passes a nil credentials when none supplied' do
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:credentials=).with(nil))

      define_tasks
    end

    it 'passes the provided credentials when supplied' do
      credentials = {
          username: 'username'
      }
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:credentials=).with(credentials))

      define_tasks do |t|
        t.credentials = credentials
      end
    end


    it 'uses an empty array for argument names by default' do
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:argument_names=).with([]))

      define_tasks
    end

    it 'uses the provided argument names when supplied' do
      build_configurer = stubbed_build_configurer

      expect(RakeDocker::Tasks::Build)
          .to(receive(:new).and_yield(build_configurer))
      expect(build_configurer)
          .to(receive(:argument_names=).with([:org_name]))

      define_tasks do |t|
        t.argument_names = [:org_name]
      end
    end
  end

  context 'tag task' do
    it 'configures with the provided image name, repository name, repository url and tags' do
      image_name = 'apache'
      repository_name = 'apache/apache'
      repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
      tags = ['latest']

      tag_configurer = stubbed_tag_configurer

      expect(RakeDocker::Tasks::Tag)
          .to(receive(:new).and_yield(tag_configurer))
      expect(tag_configurer)
          .to(receive(:image_name=).with(image_name))
      expect(tag_configurer)
          .to(receive(:repository_name=).with(repository_name))
      expect(tag_configurer)
          .to(receive(:repository_url=).with(repository_url))
      expect(tag_configurer)
          .to(receive(:tags=).with(tags))

      define_tasks do |t|
        t.image_name = image_name
        t.repository_name = repository_name
        t.repository_url = repository_url
        t.tags = tags
      end
    end

    it 'uses a name of tag by default' do
      tag_configurer = stubbed_tag_configurer

      expect(RakeDocker::Tasks::Tag)
          .to(receive(:new).and_yield(tag_configurer))
      expect(tag_configurer)
          .to(receive(:name=).with(:tag))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      tag_configurer = stubbed_tag_configurer

      expect(RakeDocker::Tasks::Tag)
          .to(receive(:new).and_yield(tag_configurer))
      expect(tag_configurer)
          .to(receive(:name=).with(:tag_it_now))

      define_tasks do |t|
        t.tag_task_name = :tag_it_now
      end
    end

    it 'uses an empty array for argument names by default' do
      tag_configurer = stubbed_tag_configurer

      expect(RakeDocker::Tasks::Tag)
          .to(receive(:new).and_yield(tag_configurer))
      expect(tag_configurer)
          .to(receive(:argument_names=).with([]))

      define_tasks
    end

    it 'uses the provided argument names when supplied' do
      tag_configurer = stubbed_tag_configurer

      expect(RakeDocker::Tasks::Tag)
          .to(receive(:new).and_yield(tag_configurer))
      expect(tag_configurer)
          .to(receive(:argument_names=).with([:org_name]))

      define_tasks do |t|
        t.argument_names = [:org_name]
      end
    end
  end

  context 'push task' do
    it 'configures with the provided image name, repository name, repository url and tags' do
      image_name = 'apache'
      repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
      tags = ['latest']

      push_configurer = stubbed_push_configurer

      expect(RakeDocker::Tasks::Push)
          .to(receive(:new).and_yield(push_configurer))
      expect(push_configurer)
          .to(receive(:image_name=).with(image_name))
      expect(push_configurer)
          .to(receive(:repository_url=).with(repository_url))
      expect(push_configurer)
          .to(receive(:tags=).with(tags))

      define_tasks do |t|
        t.image_name = image_name
        t.repository_url = repository_url
        t.tags = tags
      end
    end

    it 'uses a name of push by default' do
      push_configurer = stubbed_push_configurer

      expect(RakeDocker::Tasks::Push)
          .to(receive(:new).and_yield(push_configurer))
      expect(push_configurer)
          .to(receive(:name=).with(:push))

      define_tasks
    end

    it 'uses the provided name when supplied' do
      push_configurer = stubbed_push_configurer

      expect(RakeDocker::Tasks::Push)
          .to(receive(:new).and_yield(push_configurer))
      expect(push_configurer)
          .to(receive(:name=).with(:push_it_real_good))

      define_tasks do |t|
        t.push_task_name = :push_it_real_good
      end
    end

    it 'passes a nil credentials when none supplied' do
      push_configurer = stubbed_push_configurer

      expect(RakeDocker::Tasks::Push)
          .to(receive(:new).and_yield(push_configurer))
      expect(push_configurer)
          .to(receive(:credentials=).with(nil))

      define_tasks
    end

    it 'passes the provided credentials when supplied' do
      credentials = {
          username: 'username'
      }
      push_configurer = stubbed_push_configurer

      expect(RakeDocker::Tasks::Push)
          .to(receive(:new).and_yield(push_configurer))
      expect(push_configurer)
          .to(receive(:credentials=).with(credentials))

      define_tasks do |t|
        t.credentials = credentials
      end
    end


    it 'uses an empty array for argument names by default' do
      push_configurer = stubbed_push_configurer

      expect(RakeDocker::Tasks::Push)
          .to(receive(:new).and_yield(push_configurer))
      expect(push_configurer)
          .to(receive(:argument_names=).with([]))

      define_tasks
    end

    it 'uses the provided argument names when supplied' do
      push_configurer = stubbed_push_configurer

      expect(RakeDocker::Tasks::Push)
          .to(receive(:new).and_yield(push_configurer))
      expect(push_configurer)
          .to(receive(:argument_names=).with([:org_name]))

      define_tasks do |t|
        t.argument_names = [:org_name]
      end
    end
  end

  def define_tasks(&block)
    subject.new do |t|
      t.image_name = 'nginx'
      t.repository_name = 'my-org/nginx'
      t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

      t.work_directory = 'build'

      t.tags = ['latest']

      block.call(t) if block
    end
  end

  def double_allowing(*messages)
    instance = double
    messages.each do |message|
      allow(instance).to(receive(message))
    end
    instance
  end

  def stubbed_clean_configurer
    double_allowing(:name=, :image_name=, :work_directory=)
  end

  def stubbed_prepare_configurer
    double_allowing(:name=, :image_name=, :work_directory=,
                    :copy_spec=, :create_spec=)
  end

  def stubbed_build_configurer
    double_allowing(:name=, :argument_names=, :image_name=,
                    :repository_name=, :work_directory=,
                    :credentials=, :prepare_task=)
  end

  def stubbed_tag_configurer
    double_allowing(:name=, :argument_names=, :image_name=,
                    :repository_name=, :repository_url=,
                    :tags=)
  end

  def stubbed_push_configurer
    double_allowing(:name=, :argument_names=, :image_name=, :repository_url=,
                    :tags=, :credentials=)
  end
end
