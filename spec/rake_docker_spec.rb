# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RakeDocker do
  it 'has a version number' do
    expect(RakeDocker::VERSION).not_to be_nil
  end

  describe 'define_image_tasks' do
    context 'when instantiating RakeDocker::TaskSets::Image' do
      # rubocop:disable RSpec/MultipleExpectations
      it 'passes the provided block' do
        opts = { image_name: 'nginx' }

        block = lambda do |t|
          t.repository_name = 'my-org/nginx'
          t.repository_url = '123.dkr.ecr.eu-west-2.amazonaws.com/my-org/nginx'

          t.work_directory = 'build'

          t.tags = ['latest']
        end

        allow(RakeDocker::TaskSets::Image)
          .to(receive(:define))

        described_class.define_image_tasks(opts, &block)

        expect(RakeDocker::TaskSets::Image)
          .to(have_received(:define) do |passed_opts, &passed_block|
            expect(passed_opts).to(eq(opts))
            expect(passed_block).to(eq(block))
          end)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end

  describe 'define_container_tasks' do
    context 'when instantiating RakeDocker::TaskSets::Container' do
      # rubocop:disable RSpec/MultipleExpectations
      it 'passes the provided block' do
        opts = { container_name: 'web-server' }

        block = lambda do |t|
          t.image = 'my-org/nginx'
        end

        allow(RakeDocker::TaskSets::Container)
          .to(receive(:define))

        described_class.define_container_tasks(opts, &block)

        expect(RakeDocker::TaskSets::Container)
          .to(have_received(:define) do |passed_opts, &passed_block|
            expect(passed_opts).to(eq(opts))
            expect(passed_block).to(eq(block))
          end)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
