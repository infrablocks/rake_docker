require 'spec_helper'

RSpec.describe RakeDocker do
  it 'has a version number' do
    expect(RakeDocker::VERSION).not_to be nil
  end

  context 'define_image_tasks' do
    context 'when instantiating RakeDocker::Tasks::All' do
      it 'passes the provided block' do
        block = lambda do |t|
          t.image_name = 'nginx'
          t.repository_name = 'my-org/nginx'
          t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

          t.work_directory = 'build'

          t.tags = ['latest']
        end

        expect(RakeDocker::Tasks::All)
            .to(receive(:new) do |*_, &passed_block|
              expect(passed_block).to(eq(block))
            end)

        RakeDocker.define_image_tasks(&block)
      end
    end
  end
end
