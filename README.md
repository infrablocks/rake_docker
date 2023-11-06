# RakeDocker

Allows building, tagging and pushing images and creating, starting, stopping
and removing containers from within rake tasks.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rake_docker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rake_docker

## Usage

To define tasks for managing a docker image:

```ruby
RakeDocker.define_image_tasks(
  image_name: 'my-image'
) do |t|
  t.work_directory = 'build/images'

  t.copy_spec = [
    'src/my-image/Dockerfile',
    'src/my-image/start.sh'
  ]

  t.repository_name = 'my-image'
  t.repository_url = 'my-org/my-image'

  t.credentials = YAML.load_file(
    'config/secrets/dockerhub/credentials.yaml'
  )

  t.platform = 'linux/amd64'

  t.tags = ['1.2.3', 'latest']
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

### Managing CircleCI keys

To encrypt a GPG key for use by CircleCI:

```bash
openssl aes-256-cbc \
  -e \
  -md sha1 \
  -in ./config/secrets/ci/gpg.private \
  -out ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

To check decryption is working correctly:

```bash
openssl aes-256-cbc \
  -d \
  -md sha1 \
  -in ./.circleci/gpg.private.enc \
  -k "<passphrase>"
```

## Contributing

Bug reports and pull requests are welcome on GitHub at 
https://github.com/infrablocks/rake_docker. This project is intended to be a 
safe, welcoming space for collaboration, and contributors are expected to 
adhere to the [Contributor Covenant](http://contributor-covenant.org) code of 
conduct.

## License

The gem is available as open source under the terms of the 
[MIT License](http://opensource.org/licenses/MIT).
