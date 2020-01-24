require 'spec_helper'

describe RakeDocker::Tasks::Publish do
  include_context :rake

  it 'adds a publish task in the namespace in which it is created' do
    namespace :image do
      subject.define
    end

    expect(Rake::Task.task_defined?('image:publish')).to(be(true))
  end

  it 'gives the publish task a description' do
    namespace :image do
      subject.define(image_name: 'nginx')
    end

    expect(Rake::Task["image:publish"].full_comment)
        .to(eq("Publish nginx image"))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.define(name: :build_and_push)
    end

    expect(Rake::Task.task_defined?("image:build_and_push"))
        .to(be(true))
  end

  it 'allows multiple publish tasks to be declared' do
    namespace :image1 do
      subject.define
    end

    namespace :image2 do
      subject.define
    end

    expect(Rake::Task.task_defined?('image1:publish')).to(be(true))
    expect(Rake::Task.task_defined?('image2:publish')).to(be(true))
  end

  it 'invokes other tasks with arguments in order' do
    clean_task_stub = double('clean task')
    build_task_stub = double('build task')
    tag_task_stub = double('tag task')
    push_task_stub = double('push task')

    arguments = ["first", "second"]

    expect(clean_task_stub)
        .to(receive(:invoke).with(*arguments).ordered)
    expect(build_task_stub)
        .to(receive(:invoke).with(*arguments).ordered)
    expect(tag_task_stub)
        .to(receive(:invoke).with(*arguments).ordered)
    expect(push_task_stub)
        .to(receive(:invoke).with(*arguments).ordered)

    namespace :image do
      subject.define(argument_names: [:thing1, :thing2])
    end

    rake_task = Rake::Task["image:publish"]

    allow(Rake::Task)
        .to(receive(:[]).with("image:clean")
            .and_return(clean_task_stub))
    allow(Rake::Task)
        .to(receive(:[]).with("image:build")
            .and_return(build_task_stub))
    allow(Rake::Task)
        .to(receive(:[]).with("image:tag")
            .and_return(tag_task_stub))
    allow(Rake::Task)
        .to(receive(:[]).with("image:push")
            .and_return(push_task_stub))

    rake_task.invoke(*arguments)
  end

  it 'allows clean task name to be overridden' do
    clean_task_stub = double('clean task')
    other_task_stub = double('other task')

    arguments = ["first", "second"]

    expect(clean_task_stub)
        .to(receive(:invoke).with(*arguments))
    allow(other_task_stub).to(receive(:invoke))

    namespace :image do
      subject.define(
          clean_task_name: :clean_it,
          argument_names: [:thing1, :thing2])
    end

    rake_task = Rake::Task["image:publish"]

    allow(Rake::Task)
        .to(receive(:[]))
            .and_return(other_task_stub)
    allow(Rake::Task)
        .to(receive(:[]).with("image:clean_it")
            .and_return(clean_task_stub))

    rake_task.invoke(*arguments)
  end

  it 'allows build task name to be overridden' do
    build_task_stub = double('build task')
    other_task_stub = double('other task')

    arguments = ["first", "second"]

    expect(build_task_stub)
        .to(receive(:invoke).with(*arguments))
    allow(other_task_stub).to(receive(:invoke))

    namespace :image do
      subject.define(
          build_task_name: :build_it,
          argument_names: [:thing1, :thing2])
    end

    rake_task = Rake::Task["image:publish"]

    allow(Rake::Task)
        .to(receive(:[]))
        .and_return(other_task_stub)
    allow(Rake::Task)
        .to(receive(:[]).with("image:build_it")
            .and_return(build_task_stub))

    rake_task.invoke(*arguments)
  end

  it 'allows build task name to be overridden' do
    tag_task_stub = double('tag task')
    other_task_stub = double('other task')

    arguments = ["first", "second"]

    expect(tag_task_stub)
        .to(receive(:invoke).with(*arguments))
    allow(other_task_stub).to(receive(:invoke))

    namespace :image do
      subject.define(
          tag_task_name: :tag_it,
          argument_names: [:thing1, :thing2])
    end

    rake_task = Rake::Task["image:publish"]

    allow(Rake::Task)
        .to(receive(:[]))
        .and_return(other_task_stub)
    allow(Rake::Task)
        .to(receive(:[]).with("image:tag_it")
            .and_return(tag_task_stub))

    rake_task.invoke(*arguments)
  end

  it 'allows build task name to be overridden' do
    push_task_stub = double('push task')
    other_task_stub = double('other task')

    arguments = ["first", "second"]

    expect(push_task_stub)
        .to(receive(:invoke).with(*arguments))
    allow(other_task_stub).to(receive(:invoke))

    namespace :image do
      subject.define(
          push_task_name: :push_it,
          argument_names: [:thing1, :thing2])
    end

    rake_task = Rake::Task["image:publish"]

    allow(Rake::Task)
        .to(receive(:[]))
        .and_return(other_task_stub)
    allow(Rake::Task)
        .to(receive(:[]).with("image:push_it")
            .and_return(push_task_stub))

    rake_task.invoke(*arguments)
  end
end
