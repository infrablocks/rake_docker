# frozen_string_literal: true

require 'spec_helper'
require 'fileutils'

describe RakeDocker::TaskSets::Image do
  include_context 'rake'

  def define_tasks(opts = {}, &block)
    described_class.define({
      image_name: 'nginx',
      repository_name: 'my-org/nginx',
      repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
      work_directory: 'build',
      tags: ['latest']
    }.merge(opts), &block)
  end

  it 'adds all image tasks in the provided namespace when supplied' do
    define_tasks(namespace: :some_image)

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[some_image:clean
               some_image:prepare
               some_image:build
               some_image:tag
               some_image:push]
          ))
  end

  it 'adds all image tasks in the root namespace when none supplied' do
    define_tasks

    expect(Rake.application)
      .to(have_tasks_defined(
            %w[clean
               prepare
               build
               tag
               push]
          ))
  end

  describe 'clean task' do
    it 'configures with the provided image name' do
      image_name = 'apache'

      define_tasks(
        image_name: image_name
      )

      rake_task = Rake::Task['clean']

      expect(rake_task.creator.image_name).to(eq(image_name))
    end

    it 'configures with the provided work directory' do
      work_directory = 'tmp'

      define_tasks(
        work_directory: work_directory
      )

      rake_task = Rake::Task['clean']

      expect(rake_task.creator.work_directory).to(eq(work_directory))
    end

    it 'uses a name of clean by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('clean'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(clean_task_name: :clean_it_up)

      expect(Rake.application)
        .to(have_task_defined('clean_it_up'))
    end
  end

  describe 'prepare task' do
    it 'configures with the provided image name' do
      image_name = 'apache'

      define_tasks(
        image_name: image_name
      )

      rake_task = Rake::Task['prepare']

      expect(rake_task.creator.image_name).to(eq(image_name))
    end

    it 'configures with the provided work directory' do
      work_directory = 'tmp'

      define_tasks(
        work_directory: work_directory
      )

      rake_task = Rake::Task['prepare']

      expect(rake_task.creator.work_directory).to(eq(work_directory))
    end

    it 'passes the default copy spec when none supplied' do
      define_tasks

      rake_task = Rake::Task['prepare']

      expect(rake_task.creator.copy_spec).to(eq([]))
    end

    it 'passes the provided copy spec when supplied' do
      copy_spec = %w[file1.txt file2.rb]

      define_tasks(copy_spec: copy_spec)

      rake_task = Rake::Task['prepare']

      expect(rake_task.creator.copy_spec).to(eq(copy_spec))
    end

    it 'passes the default create spec when none supplied' do
      define_tasks

      rake_task = Rake::Task['prepare']

      expect(rake_task.creator.create_spec).to(eq([]))
    end

    it 'passes the provided create spec when supplied' do
      create_spec = [
        { content: 'some-content', to: 'some-file.txt' }
      ]

      define_tasks(create_spec: create_spec)

      rake_task = Rake::Task['prepare']

      expect(rake_task.creator.create_spec).to(eq(create_spec))
    end

    it 'uses a name of prepare by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('prepare'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(prepare_task_name: :prepare_for_build)

      expect(Rake.application)
        .to(have_task_defined('prepare_for_build'))
    end
  end

  describe 'build task' do
    it 'configures with the provided image name' do
      image_name = 'apache'

      define_tasks(
        image_name: image_name
      )

      rake_task = Rake::Task['build']

      expect(rake_task.creator.image_name).to(eq(image_name))
    end

    it 'configures with the provided repository name' do
      repository_name = 'apache/apache'

      define_tasks(
        repository_name: repository_name
      )

      rake_task = Rake::Task['build']

      expect(rake_task.creator.repository_name).to(eq(repository_name))
    end

    it 'configures with the provided work directory' do
      work_directory = 'tmp'

      define_tasks(
        work_directory: work_directory
      )

      rake_task = Rake::Task['build']

      expect(rake_task.creator.work_directory).to(eq(work_directory))
    end

    it 'uses a name of build by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('build'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(build_task_name: :build_it_now)

      expect(Rake.application)
        .to(have_task_defined('build_it_now'))
    end

    it 'uses a prepare task name of prepare by default' do
      define_tasks

      rake_task = Rake::Task['build']

      expect(rake_task.creator.prepare_task_name).to(eq(:prepare))
    end

    it 'uses the provided prepare task name when supplied' do
      define_tasks(prepare_task_name: :prepare_it)

      rake_task = Rake::Task['build']

      expect(rake_task.creator.prepare_task_name).to(eq(:prepare_it))
    end

    it 'passes a nil credentials when none supplied' do
      define_tasks

      rake_task = Rake::Task['build']

      expect(rake_task.creator.credentials).to(be_nil)
    end

    it 'passes the provided credentials when supplied' do
      credentials = {
        username: 'username'
      }

      define_tasks(credentials: credentials)

      rake_task = Rake::Task['build']

      expect(rake_task.creator.credentials).to(eq(credentials))
    end

    it 'passes a nil build args when none supplied' do
      define_tasks

      rake_task = Rake::Task['build']

      expect(rake_task.creator.build_args).to(be_nil)
    end

    it 'passes the provided build args when supplied' do
      build_args = {
        SOMETHING_IMPORTANT: 'the-value'
      }

      define_tasks(build_args: build_args)

      rake_task = Rake::Task['build']

      expect(rake_task.creator.build_args).to(eq(build_args))
    end

    it 'passes a nil platform when none supplied' do
      define_tasks

      rake_task = Rake::Task['build']

      expect(rake_task.creator.platform).to(be_nil)
    end

    it 'passes the provided platform when supplied' do
      platform = 'linux/amd64'

      define_tasks(platform: platform)

      rake_task = Rake::Task['build']

      expect(rake_task.creator.platform).to(eq(platform))
    end

    it 'uses an empty array for argument names by default' do
      define_tasks

      rake_task = Rake::Task['build']

      expect(rake_task.creator.argument_names).to(eq([]))
    end

    it 'uses the provided argument names when supplied' do
      define_tasks(argument_names: [:org_name])

      rake_task = Rake::Task['build']

      expect(rake_task.creator.argument_names).to(eq([:org_name]))
    end
  end

  describe 'tag task' do
    it 'configures with the provided image name' do
      image_name = 'apache'

      define_tasks(
        image_name: image_name
      )

      rake_task = Rake::Task['tag']

      expect(rake_task.creator.image_name).to(eq(image_name))
    end

    it 'configures with the provided repository name' do
      repository_name = 'apache/apache'

      define_tasks(
        repository_name: repository_name
      )

      rake_task = Rake::Task['tag']

      expect(rake_task.creator.repository_name).to(eq(repository_name))
    end

    it 'configures with the provided repository url' do
      repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

      define_tasks(
        repository_url: repository_url
      )

      rake_task = Rake::Task['tag']

      expect(rake_task.creator.repository_url).to(eq(repository_url))
    end

    it 'configures with the provided tags' do
      tags = ['latest']

      define_tasks(
        tags: tags
      )

      rake_task = Rake::Task['tag']

      expect(rake_task.creator.tags).to(eq(tags))
    end

    it 'uses a name of tag by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('tag'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(tag_task_name: :tag_it_now)

      expect(Rake.application)
        .to(have_task_defined('tag_it_now'))
    end

    it 'uses an empty array for argument names by default' do
      define_tasks

      rake_task = Rake::Task['tag']

      expect(rake_task.creator.argument_names).to(eq([]))
    end

    it 'uses the provided argument names when supplied' do
      define_tasks(argument_names: [:org_name])

      rake_task = Rake::Task['tag']

      expect(rake_task.creator.argument_names).to(eq([:org_name]))
    end
  end

  describe 'push task' do
    it 'configures with the provided image name' do
      image_name = 'apache'

      define_tasks(
        image_name: image_name
      )

      rake_task = Rake::Task['push']

      expect(rake_task.creator.image_name).to(eq(image_name))
    end

    it 'configures with the provided repository url' do
      repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

      define_tasks(
        repository_url: repository_url
      )

      rake_task = Rake::Task['push']

      expect(rake_task.creator.repository_url).to(eq(repository_url))
    end

    it 'configures with the provided tags' do
      tags = ['latest']

      define_tasks(
        tags: tags
      )

      rake_task = Rake::Task['push']

      expect(rake_task.creator.tags).to(eq(tags))
    end

    it 'uses a name of push by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('push'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(push_task_name: :push_it_real_good)

      expect(Rake.application)
        .to(have_task_defined('push_it_real_good'))
    end

    it 'passes a nil credentials when none supplied' do
      define_tasks

      rake_task = Rake::Task['push']

      expect(rake_task.creator.credentials).to(be_nil)
    end

    it 'passes the provided credentials when supplied' do
      credentials = {
        username: 'username'
      }

      define_tasks(credentials: credentials)

      rake_task = Rake::Task['push']

      expect(rake_task.creator.credentials).to(eq(credentials))
    end

    it 'uses an empty array for argument names by default' do
      define_tasks

      rake_task = Rake::Task['push']

      expect(rake_task.creator.argument_names).to(eq([]))
    end

    it 'uses the provided argument names when supplied' do
      define_tasks(argument_names: [:org_name])

      rake_task = Rake::Task['push']

      expect(rake_task.creator.argument_names).to(eq([:org_name]))
    end
  end

  describe 'publish task' do
    it 'configures with the provided image name' do
      image_name = 'apache'

      define_tasks(image_name: image_name)

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.image_name).to(eq(image_name))
    end

    it 'uses a name of publish by default' do
      define_tasks

      expect(Rake.application)
        .to(have_task_defined('publish'))
    end

    it 'uses the provided name when supplied' do
      define_tasks(push_task_name: :publish_it_real_good)

      expect(Rake.application)
        .to(have_task_defined('publish_it_real_good'))
    end

    it 'passes default clean task name to publish' do
      define_tasks

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.clean_task_name).to(be(:clean))
    end

    it 'passes default build task name to publish' do
      define_tasks

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.build_task_name).to(be(:build))
    end

    it 'passes default tag task name to publish' do
      define_tasks

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.tag_task_name).to(be(:tag))
    end

    it 'passes default push task name to publish' do
      define_tasks

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.push_task_name).to(be(:push))
    end

    it 'passes custom clean task name to publish' do
      define_tasks(
        clean_task_name: :clean_it_up
      )

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.clean_task_name).to(be(:clean_it_up))
    end

    it 'passes custom build task name to publish' do
      define_tasks(
        build_task_name: :build_it_up
      )

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.build_task_name).to(be(:build_it_up))
    end

    it 'passes custom tag task name to publish' do
      define_tasks(
        tag_task_name: :tag_it_up
      )

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.tag_task_name).to(be(:tag_it_up))
    end

    it 'passes custom push task name to publish' do
      define_tasks(
        push_task_name: :push_it_up
      )

      rake_task = Rake::Task['publish']

      expect(rake_task.creator.push_task_name).to(be(:push_it_up))
    end
  end
end
