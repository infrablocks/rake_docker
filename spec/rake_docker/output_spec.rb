# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RakeDocker::Output do
  before do
    stub_prints
  end

  it 'is able to handle invalid JSON' do
    chunk = 'not a valid JSON'

    described_class.print(chunk)

    expect($stdout).to(have_received(:print).with(chunk))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'handles multiline chunks' do
    chunk = "\nline 1\nline 2\n"

    described_class.print(chunk)

    expect($stdout).to(have_received(:print).with("\n"))
    expect($stdout).to(have_received(:print).with("line 1\n"))
    expect($stdout).to(have_received(:print).with("line 2\n"))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'skips progress status' do
    chunk = '{"status":"Downloading","progressDetail":' \
            '{"current":185116,"total":17538077},"progress":' \
            '"[\u003e                                                  ]  ' \
            '185.1kB/17.54MB","id":"46dde23c37b3"}'

    described_class.print(chunk)

    expect($stdout).not_to(have_received(:print))
  end

  it 'skips progress aux' do
    chunk = '{"progressDetail":{},"aux":{"Tag":"0.1.0-20180924122438",' \
            '"Digest":"sha256:e405ec36144686fb704c14c18e7fc512266dbb95' \
            'fadd9a27df8c9f530c71e305","Size":2844}}'

    described_class.print(chunk)

    expect($stdout).not_to(have_received(:print))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'detects an error' do
    chunk = '{"errorDetail":{"message":"name unknown: The repository with ' \
            'name \'test-repo\' does not exist in the registry with id ' \
            '\'123456780102\'"},"error":"name unknown: The repository with ' \
            'name \'test-repo\' does not exist in the registry with id ' \
            '\'123456780102\'"}'

    expect do
      described_class.print(chunk)
    end.to(raise_error(
             RuntimeError,
             "name unknown: The repository with name 'test-repo' does not " \
             "exist in the registry with id '123456780102'"
           ))

    expected_error = "name unknown: The repository with name 'test-repo' " \
                     "does not exist in the registry with id '123456780102'"
    expect($stdout)
      .to(have_received(:print)
            .with("#{expected_error.red}\n"))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'parses stream' do
    chunk = '{"stream":"Step 1/8 : FROM openjdk:8-jre"}'

    described_class.print(chunk)

    expect($stdout)
      .to(have_received(:print)
            .with('Step 1/8 : FROM openjdk:8-jre'))
  end

  # rubocop:disable RSpec/MultipleExpectations
  it 'parses multiple stream chunks' do
    chunk = "{\"stream\":\"Step 1/8 : FROM openjdk:8-jre\"}\n" \
            '{"stream":"\\n"}'

    described_class.print(chunk)

    expect($stdout)
      .to(have_received(:print)
            .with('Step 1/8 : FROM openjdk:8-jre'))
    expect($stdout)
      .to(have_received(:print)
            .with("\n"))
  end
  # rubocop:enable RSpec/MultipleExpectations

  it 'parses status with id' do
    chunk = '{"status":"Waiting","progressDetail":{},"id":"1290813abd9d"}'

    described_class.print(chunk)

    expect($stdout)
      .to(have_received(:print)
            .with("1290813abd9d: Waiting\n"))
  end

  it 'parses status without id' do
    chunk = '{"status":"Status: Downloaded newer image for openjdk:8-jre"}'

    described_class.print(chunk)

    expect($stdout)
      .to(have_received(:print)
            .with("Status: Downloaded newer image for openjdk:8-jre\n"))
  end

  it 'passes unrecognized JSON' do
    chunk = '{"test":"test"}'

    described_class.print(chunk)

    expect($stdout)
      .to(have_received(:print)
            .with(chunk))
  end

  def stub_prints
    allow($stdout).to(receive(:print))
    allow($stderr).to(receive(:print))
  end
end
