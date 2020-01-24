# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rake_docker/version'

Gem::Specification.new do |spec|
  spec.name          = 'rake_docker'
  spec.version       = RakeDocker::VERSION
  spec.authors       = ['Toby Clemson']
  spec.email         = ['tobyclemson@gmail.com']

  spec.summary       = 'Rake tasks for managing images and containers.'
  spec.description   = 'Allows building, tagging and pushing images and creating, starting, stopping and removing containers from within rake tasks.'
  spec.homepage      = "https://github.com/tobyclemson/rake_docker"
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6'

  spec.add_dependency 'docker-api', '~> 1.34'
  spec.add_dependency 'rake_factory', '~> 0.15'
  spec.add_dependency 'aws-sdk-ecr', '~> 1.2'
  spec.add_dependency 'colored2', '~> 3.1'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'gem-release', '~> 2.0'
  spec.add_development_dependency 'activesupport', '~> 5.2'
  spec.add_development_dependency 'memfs', '~> 1.0'
  spec.add_development_dependency 'simplecov', '~> 0.16'
end
