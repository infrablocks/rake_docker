require 'spec_helper'

RSpec.describe DockerOutput do
  before(:each) do
    stub_puts
  end

  it 'is able to handle invalid JSON' do
    chunk = 'not a valid JSON'

    expect($stdout).to(receive(:puts).with(chunk))

    DockerOutput.puts(chunk)
  end

  it 'is handles multiline' do
    chunk = %{
line 1
line 2
}

    expect($stdout).to(receive(:puts).with("\n"))
    expect($stdout).to(receive(:puts).with("line 1\n"))
    expect($stdout).to(receive(:puts).with("line 2\n"))

    DockerOutput.puts(chunk)
  end

  it 'skips progress status' do
    chunk = '{"status":"Downloading","progressDetail":{"current":185116,"total":17538077},"progress":"[\u003e                                                  ]  185.1kB/17.54MB","id":"46dde23c37b3"}'

    expect($stdout).not_to(receive(:puts))

    DockerOutput.puts(chunk)
  end

  it 'skips progress aux' do
    chunk = '{"progressDetail":{},"aux":{"Tag":"0.1.0-20180924122438","Digest":"sha256:e405ec36144686fb704c14c18e7fc512266dbb95fadd9a27df8c9f530c71e305","Size":2844}}'

    expect($stdout).not_to(receive(:puts))

    DockerOutput.puts(chunk)
  end

  it 'detects an error' do
    chunk = <<-JSON
{"errorDetail":{"message":"name unknown: The repository with name 'test-repo' does not exist in the registry with id '123456780102'"},"error":"name unknown: The repository with name 'test-repo' does not exist in the registry with id '123456780102'"}
JSON

    expect($stdout).to(receive(:puts).with("name unknown: The repository with name 'test-repo' does not exist in the registry with id '123456780102'".red))

	expect {
      DockerOutput.puts(chunk)
    }.to raise_error(RuntimeError, "name unknown: The repository with name 'test-repo' does not exist in the registry with id '123456780102'")
  end

  it 'parses stream' do
    chunk = '{"stream":"Step 1/8 : FROM openjdk:8-jre"}'

    expect($stdout).to(receive(:puts).with('Step 1/8 : FROM openjdk:8-jre'))

    DockerOutput.puts(chunk)
  end

  it 'parses multiple stream chunks' do
    chunk = <<-JSON
{"stream":"Step 1/8 : FROM openjdk:8-jre"}
{"stream":"\\n"}
JSON

    expect($stdout).to(receive(:puts).with('Step 1/8 : FROM openjdk:8-jre'))
    expect($stdout).to(receive(:puts).with("\n"))

    DockerOutput.puts(chunk)
  end

  it 'parses status with id' do
    chunk = '{"status":"Waiting","progressDetail":{},"id":"1290813abd9d"}'

    expect($stdout).to(receive(:puts).with('1290813abd9d: Waiting'))

    DockerOutput.puts(chunk)
  end

  it 'parses status without id' do
    chunk = '{"status":"Status: Downloaded newer image for openjdk:8-jre"}'

    expect($stdout).to(receive(:puts).with('Status: Downloaded newer image for openjdk:8-jre'))

    DockerOutput.puts(chunk)
  end

  it 'passes unrecognized JSON' do
    chunk = '{"test":"test"}'

    expect($stdout).to(receive(:puts).with(chunk))

    DockerOutput.puts(chunk)
  end

  def stub_puts
    allow_any_instance_of(Kernel).to(receive(:puts))
    allow($stdout).to(receive(:puts))
    allow($stderr).to(receive(:puts))
  end
end
