# frozen_string_literal: true

require 'spec_helper'

describe RakeDocker::Tasks::Prepare do
  include_context 'rake'

  before do
    stub_puts
  end

  it 'adds a prepare task in the namespace in which it is created' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build'
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:prepare'))
  end

  it 'gives the prepare task a description' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build'
      )
    end

    expect(Rake::Task['image:prepare'].full_comment)
      .to(eq('Prepare for build of nginx image'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      described_class.define(
        name: :assemble,
        image_name: 'nginx',
        work_directory: 'build'
      )
    end

    expect(Rake.application)
      .to(have_task_defined('image:assemble'))
  end

  it 'allows multiple prepare tasks to be declared' do
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
            %w[image1:prepare
               image2:prepare]
          ))
  end

  it 'fails if no image name is provided' do
    described_class.define(work_directory: 'build')

    expect do
      Rake::Task['prepare'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'fails if no work directory is provided' do
    described_class.define(image_name: 'thing')

    expect do
      Rake::Task['prepare'].invoke
    end.to raise_error(RakeFactory::RequiredParameterUnset)
  end

  it 'recursively makes the build directory' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build'
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx')).to(be(true))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'copies files into the build directory' do
    File.open('file1.txt', 'w') { |f| f.write('file1') }
    File.open('file2.rb', 'w') { |f| f.write('file2') }

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',
        copy_spec: %w[file1.txt file2.rb]
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/file2.rb')).to(be(true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'renames files on copy' do
    File.open('file1.txt', 'w') { |f| f.write('file1') }
    File.open('file2.rb', 'w') { |f| f.write('file2') }

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',

        copy_spec: [
          { from: 'file1.txt', to: 'copied_file1.txt' },
          { from: 'file2.rb', to: 'copied_file2.rb' }
        ]
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/copied_file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/copied_file2.rb')).to(be(true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'copies full directory when the source is a directory' do
    FileUtils.mkdir_p('source')
    File.open('source/file1.txt', 'w') { |f| f.write('file1') }
    File.open('source/file2.rb', 'w') { |f| f.write('file2') }

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',
        copy_spec: ['source']
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/source/file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/source/file2.rb')).to(be(true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'copies directory contents when the source refers to directory contents' do
    FileUtils.mkdir_p('source')
    File.open('source/file1.txt', 'w') { |f| f.write('file1') }
    File.open('source/file2.rb', 'w') { |f| f.write('file2') }

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',
        copy_spec: ['source/.']
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/file2.rb')).to(be(true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates and copies into a destination directory' do
    FileUtils.mkdir_p('source')
    File.open('source/file1.txt', 'w') { |f| f.write('file1') }
    File.open('source/file2.rb', 'w') { |f| f.write('file2') }

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',
        copy_spec: [{ from: 'source/.', to: 'the/destination' }]
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/the/destination/file1.txt'))
      .to(be(true))
    expect(File.exist?('build/nginx/the/destination/file2.rb'))
      .to(be(true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'copies nested files' do
    FileUtils.mkdir_p('source')
    File.open('source/file1.txt', 'w') { |f| f.write('file1') }
    File.open('source/file2.rb', 'w') { |f| f.write('file2') }

    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',
        copy_spec: [
          { from: 'source/file1.txt', to: 'the/destination/file1.txt' },
          { from: 'source/file2.rb', to: 'the/destination/file2.rb' }
        ]
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/the/destination/file1.txt'))
      .to(be(true))
    expect(File.exist?('build/nginx/the/destination/file2.rb'))
      .to(be(true))
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates file from content' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',
        create_spec: [
          { content: 'some-content', to: 'some-file.txt' }
        ]
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/some-file.txt')).to(be(true))
    expect(File.read('build/nginx/some-file.txt')).to(eq('some-content'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:disable RSpec/MultipleExpectations
  it 'creates destination directory when specified' do
    namespace :image do
      described_class.define(
        image_name: 'nginx',
        work_directory: 'build',
        create_spec: [
          { content: 'some-content', to: 'some-directory/some-file.txt' }
        ]
      )
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/some-directory/some-file.txt'))
      .to(be(true))
    expect(File.read('build/nginx/some-directory/some-file.txt'))
      .to(eq('some-content'))
  end
  # rubocop:enable RSpec/MultipleExpectations

  def stub_puts
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end
end
