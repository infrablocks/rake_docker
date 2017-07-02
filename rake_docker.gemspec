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

  spec.required_ruby_version = '>= 2.0'

  spec.add_dependency 'docker-api', '~> 1.33'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'gem-release', '~> 0.7'
  spec.add_development_dependency 'activesupport', '~> 4.2'
  spec.add_development_dependency 'memfs', '~> 1.0'
  spec.add_development_dependency 'simplecov', '~> 0.13'
end
