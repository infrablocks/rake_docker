require 'spec_helper'
require 'fileutils'

describe RakeDocker::TaskSets::Image do
  include_context :rake

  def define_tasks(opts = {}, &block)
    subject.define({
        image_name: 'nginx',
        repository_name: 'my-org/nginx',
        repository_url: '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx',
        work_directory: 'build',
        tags: ['latest']
    }.merge(opts), &block)
  end

  it 'adds all image tasks in the provided namespace when supplied' do
    define_tasks(namespace: :some_image)

    expect(Rake::Task.task_defined?('some_image:clean')).to(be(true))
    expect(Rake::Task.task_defined?('some_image:prepare')).to(be(true))
    expect(Rake::Task.task_defined?('some_image:build')).to(be(true))
    expect(Rake::Task.task_defined?('some_image:tag')).to(be(true))
    expect(Rake::Task.task_defined?('some_image:push')).to(be(true))
  end

  it 'adds all image tasks in the root namespace when none supplied' do
    define_tasks

    expect(Rake::Task.task_defined?('clean')).to(be(true))
    expect(Rake::Task.task_defined?('prepare')).to(be(true))
    expect(Rake::Task.task_defined?('build')).to(be(true))
    expect(Rake::Task.task_defined?('tag')).to(be(true))
    expect(Rake::Task.task_defined?('push')).to(be(true))
  end

  context 'clean task' do
    it 'configures with the provided image name and work directory' do
      image_name = 'apache'
      work_directory = 'tmp'

      define_tasks(
          image_name: image_name,
          work_directory: work_directory)

      rake_task = Rake::Task["clean"]

      expect(rake_task.creator.image_name).to(eq(image_name))
      expect(rake_task.creator.work_directory).to(eq(work_directory))
    end

    it 'uses a name of clean by default' do
      define_tasks

      expect(Rake::Task.task_defined?("clean")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(clean_task_name: :clean_it_up)

      expect(Rake::Task.task_defined?("clean_it_up")).to(be(true))
    end
  end

  context 'prepare task' do
    it 'configures with the provided image name and work directory' do
      image_name = 'apache'
      work_directory = 'tmp'

      define_tasks(
          image_name: image_name,
          work_directory: work_directory)

      rake_task = Rake::Task["prepare"]

      expect(rake_task.creator.image_name).to(eq(image_name))
      expect(rake_task.creator.work_directory).to(eq(work_directory))
    end

    it 'passes the default copy spec when none supplied' do
      define_tasks

      rake_task = Rake::Task["prepare"]

      expect(rake_task.creator.copy_spec).to(eq([]))
    end

    it 'passes the provided copy spec when supplied' do
      copy_spec = ['file1.txt', 'file2.rb']

      define_tasks(copy_spec: copy_spec)

      rake_task = Rake::Task["prepare"]

      expect(rake_task.creator.copy_spec).to(eq(copy_spec))
    end

    it 'passes the default create spec when none supplied' do
      define_tasks

      rake_task = Rake::Task["prepare"]

      expect(rake_task.creator.create_spec).to(eq([]))
    end

    it 'passes the provided create spec when supplied' do
      create_spec = [
          {content: 'some-content', to: 'some-file.txt'}
      ]

      define_tasks(create_spec: create_spec)

      rake_task = Rake::Task["prepare"]

      expect(rake_task.creator.create_spec).to(eq(create_spec))
    end

    it 'uses a name of prepare by default' do
      define_tasks

      expect(Rake::Task.task_defined?("prepare")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(prepare_task_name: :prepare_for_build)

      expect(Rake::Task.task_defined?("prepare_for_build")).to(be(true))
    end
  end

  context 'build task' do
    it 'configures with the provided image name and work directory' do
      image_name = 'apache'
      repository_name = 'apache/apache'
      work_directory = 'tmp'

      define_tasks(
          image_name: image_name,
          repository_name: repository_name,
          work_directory: work_directory)

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.image_name).to(eq(image_name))
      expect(rake_task.creator.repository_name).to(eq(repository_name))
      expect(rake_task.creator.work_directory).to(eq(work_directory))
    end

    it 'uses a name of build by default' do
      define_tasks

      expect(Rake::Task.task_defined?("build")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(build_task_name: :build_it_now)

      expect(Rake::Task.task_defined?("build_it_now")).to(be(true))
    end

    it 'uses a prepare task name of prepare by default' do
      define_tasks

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.prepare_task_name).to(eq(:prepare))
    end

    it 'uses the provided prepare task name when supplied' do
      define_tasks(prepare_task_name: :prepare_it)

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.prepare_task_name).to(eq(:prepare_it))
    end

    it 'passes a nil credentials when none supplied' do
      define_tasks

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.credentials).to(be_nil)
    end

    it 'passes the provided credentials when supplied' do
      credentials = {
          username: 'username'
      }

      define_tasks(credentials: credentials)

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.credentials).to(eq(credentials))
    end

    it 'passes a nil build args when none supplied' do
      define_tasks

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.build_args).to(be_nil)
    end

    it 'passes the provided build args when supplied' do
      build_args = {
          SOMETHING_IMPORTANT: 'the-value'
      }

      define_tasks(build_args: build_args)

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.build_args).to(eq(build_args))
    end

    it 'uses an empty array for argument names by default' do
      define_tasks

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.argument_names).to(eq([]))
    end

    it 'uses the provided argument names when supplied' do
      define_tasks(argument_names: [:org_name])

      rake_task = Rake::Task["build"]

      expect(rake_task.creator.argument_names).to(eq([:org_name]))
    end
  end

  context 'tag task' do
    it 'configures with the provided image name, repository name, repository url and tags' do
      image_name = 'apache'
      repository_name = 'apache/apache'
      repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
      tags = ['latest']

      define_tasks(
          image_name: image_name,
          repository_name: repository_name,
          repository_url: repository_url,
          tags: tags)

      rake_task = Rake::Task["tag"]

      expect(rake_task.creator.image_name).to(eq(image_name))
      expect(rake_task.creator.repository_name).to(eq(repository_name))
      expect(rake_task.creator.repository_url).to(eq(repository_url))
      expect(rake_task.creator.tags).to(eq(tags))
    end

    it 'uses a name of tag by default' do
      define_tasks

      expect(Rake::Task.task_defined?("tag")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(tag_task_name: :tag_it_now)

      expect(Rake::Task.task_defined?("tag_it_now")).to(be(true))
    end

    it 'uses an empty array for argument names by default' do
      define_tasks

      rake_task = Rake::Task["tag"]

      expect(rake_task.creator.argument_names).to(eq([]))
    end

    it 'uses the provided argument names when supplied' do
      define_tasks(argument_names: [:org_name])

      rake_task = Rake::Task["tag"]

      expect(rake_task.creator.argument_names).to(eq([:org_name]))
    end
  end

  context 'push task' do
    it 'configures with the provided image name, repository name, repository url and tags' do
      image_name = 'apache'
      repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'
      tags = ['latest']

      define_tasks(
          image_name: image_name,
          repository_url: repository_url,
          tags: tags)

      rake_task = Rake::Task["push"]

      expect(rake_task.creator.image_name).to(eq(image_name))
      expect(rake_task.creator.repository_url).to(eq(repository_url))
      expect(rake_task.creator.tags).to(eq(tags))
    end

    it 'uses a name of push by default' do
      define_tasks

      expect(Rake::Task.task_defined?("push")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(push_task_name: :push_it_real_good)

      expect(Rake::Task.task_defined?("push_it_real_good")).to(be(true))
    end

    it 'passes a nil credentials when none supplied' do
      define_tasks

      rake_task = Rake::Task["push"]

      expect(rake_task.creator.credentials).to(be_nil)
    end

    it 'passes the provided credentials when supplied' do
      credentials = {
          username: 'username'
      }

      define_tasks(credentials: credentials)

      rake_task = Rake::Task["push"]

      expect(rake_task.creator.credentials).to(eq(credentials))
    end


    it 'uses an empty array for argument names by default' do
      define_tasks

      rake_task = Rake::Task["push"]

      expect(rake_task.creator.argument_names).to(eq([]))
    end

    it 'uses the provided argument names when supplied' do
      define_tasks(argument_names: [:org_name])

      rake_task = Rake::Task["push"]

      expect(rake_task.creator.argument_names).to(eq([:org_name]))
    end
  end

  context 'publish task' do
    it 'configures with the provided image name' do
      image_name = 'apache'

      define_tasks(image_name: image_name)

      rake_task = Rake::Task["publish"]

      expect(rake_task.creator.image_name).to(eq(image_name))
    end

    it 'uses a name of publish by default' do
      define_tasks

      expect(Rake::Task.task_defined?("publish")).to(be(true))
    end

    it 'uses the provided name when supplied' do
      define_tasks(push_task_name: :publish_it_real_good)

      expect(Rake::Task.task_defined?("publish_it_real_good")).to(be(true))
    end

    it 'passes other task names to publish' do
      define_tasks

      rake_task = Rake::Task["publish"]

      expect(rake_task.creator.clean_task_name).to(be(:clean))
      expect(rake_task.creator.build_task_name).to(be(:build))
      expect(rake_task.creator.tag_task_name).to(be(:tag))
      expect(rake_task.creator.push_task_name).to(be(:push))
    end

    it 'passes custom task names to publish' do
      define_tasks(
          clean_task_name: :clean_it_up,
          build_task_name: :build_it_up,
          tag_task_name: :tag_it_up,
          push_task_name: :push_it_up)

      rake_task = Rake::Task["publish"]

      expect(rake_task.creator.clean_task_name).to(be(:clean_it_up))
      expect(rake_task.creator.build_task_name).to(be(:build_it_up))
      expect(rake_task.creator.tag_task_name).to(be(:tag_it_up))
      expect(rake_task.creator.push_task_name).to(be(:push_it_up))
    end
  end
end
