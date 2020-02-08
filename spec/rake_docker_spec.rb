require 'spec_helper'

RSpec.describe RakeDocker do
  it 'has a version number' do
    expect(RakeDocker::VERSION).not_to be nil
  end

  context 'define_image_tasks' do
    context 'when instantiating RakeDocker::Tasks::Image' do
      it 'passes the provided block' do
        opts = {image_name: 'nginx'}

        block = lambda do |t|
          t.repository_name = 'my-org/nginx'
          t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

          t.work_directory = 'build'

          t.tags = ['latest']
        end

        expect(RakeDocker::TaskSets::Image)
            .to(receive(:define) do |passed_opts, &passed_block|
              expect(passed_opts).to(eq(opts))
              expect(passed_block).to(eq(block))
            end)

        RakeDocker.define_image_tasks(opts, &block)
      end
    end
  end
end
