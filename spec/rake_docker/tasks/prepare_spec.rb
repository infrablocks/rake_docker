require 'spec_helper'

describe RakeDocker::Tasks::Prepare do
  include_context :rake

  before(:each) do
    stub_puts
  end

  it 'adds a prepare task in the namespace in which it is created' do
    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'
      end
    end

    expect(Rake::Task['image:prepare']).not_to be_nil
  end

  it 'gives the prepare task a description' do
    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'
      end
    end

    expect(rake.last_description).to(eq('Prepare for build of nginx image'))
  end

  it 'allows the task name to be overridden' do
    namespace :image do
      subject.new(:assemble) do |t|
        t.image = 'nginx'
        t.work_directory = 'build'
      end
    end

    expect(Rake::Task['image:assemble']).not_to be_nil
  end

  it 'allows multiple prepare tasks to be declared' do
    namespace :image1 do
      subject.new do |t|
        t.image = 'image1'
        t.work_directory = 'build'
      end
    end

    namespace :image2 do
      subject.new do |t|
        t.image = 'image2'
        t.work_directory = 'build'
      end
    end

    image1_prepare = Rake::Task['image1:prepare']
    image2_prepare = Rake::Task['image2:prepare']

    expect(image1_prepare).not_to be_nil
    expect(image2_prepare).not_to be_nil
  end

  it 'fails if no image is provided' do
    expect {
      subject.new
    }.to raise_error(RakeDocker::RequiredParameterUnset)
  end

  it 'recursively makes the build directory' do
    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx')).to(be(true))
  end

  it 'copies files into the build directory' do
    File.open('file1.txt', 'w') { |f| f.write('file1') }
    File.open('file2.rb', 'w') { |f| f.write('file2') }

    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'

        t.copy_spec = ['file1.txt', 'file2.rb']
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/file2.rb')).to(be(true))
  end

  it 'renames files on copy' do
    File.open('file1.txt', 'w') {|f| f.write('file1')}
    File.open('file2.rb', 'w') {|f| f.write('file2')}

    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'

        t.copy_spec = [
            {from: 'file1.txt', to: 'copied_file1.txt'},
            {from: 'file2.rb', to: 'copied_file2.rb'}
        ]
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/copied_file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/copied_file2.rb')).to(be(true))
  end

  it 'copies full directory when the source is a directory' do
    FileUtils.mkdir_p('source')
    File.open('source/file1.txt', 'w') {|f| f.write('file1')}
    File.open('source/file2.rb', 'w') {|f| f.write('file2')}

    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'

        t.copy_spec = ['source']
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/source/file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/source/file2.rb')).to(be(true))
  end

  it 'copies directory contents when the source refers to directory contents' do
    FileUtils.mkdir_p('source')
    File.open('source/file1.txt', 'w') {|f| f.write('file1')}
    File.open('source/file2.rb', 'w') {|f| f.write('file2')}

    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'

        t.copy_spec = ['source/.']
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/file2.rb')).to(be(true))
  end

  it 'creates and copies into a destination directory' do
    FileUtils.mkdir_p('source')
    File.open('source/file1.txt', 'w') {|f| f.write('file1')}
    File.open('source/file2.rb', 'w') {|f| f.write('file2')}

    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'

        t.copy_spec = [{from: 'source/.', to: 'the/destination'}]
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/the/destination/file1.txt')).to(be(true))
    expect(File.exist?('build/nginx/the/destination/file2.rb')).to(be(true))
  end

  it 'creates file from content' do
    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'

        t.create_spec = [
            {content: 'some-content', to: 'some-file.txt'}
        ]
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/some-file.txt')).to(be(true))
    expect(File.read('build/nginx/some-file.txt')).to(eq('some-content'))
  end

  it 'creates destination directory when specified' do
    namespace :image do
      subject.new do |t|
        t.image = 'nginx'
        t.work_directory = 'build'

        t.create_spec = [
            {content: 'some-content', to: 'some-directory/some-file.txt'}
        ]
      end
    end

    Rake::Task['image:prepare'].invoke

    expect(File.exist?('build/nginx/some-directory/some-file.txt')).to(be(true))
    expect(File.read('build/nginx/some-directory/some-file.txt'))
        .to(eq('some-content'))
  end

  def stub_puts
    allow_any_instance_of(Kernel).to(receive(:puts))
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end
end