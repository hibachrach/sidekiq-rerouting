# Sidekiq::Rerouting

[![CI](https://github.com/hibachrach/sidekiq-disposal/actions/workflows/main.yml/badge.svg)](https://github.com/hibachrach/sidekiq-disposal/actions)

A [Sidekiq][sidekiq] extension to set Sidekiq jobs to be rerouted to a different queue based on the job ID or job class.

## Installation

TODO: Replace `UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG` with your gem name right after releasing it to RubyGems.org. Please do not do it earlier due to security reasons. Alternatively, replace this section with instructions to install your gem from git if you don't plan to release to RubyGems.org.

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install UPDATE_WITH_YOUR_GEM_NAME_IMMEDIATELY_AFTER_RELEASE_TO_RUBYGEMS_ORG
```

## Usage

From a console (Rails console, or the like) you need a `Sidekiq::Rerouting::Client` instance, which is used to `#reroute` a job, or job class to be disposed.

```ruby
client = Sidekiq::Disposal::Client.new
```

### Marking to reroute

A job marked to be rerouted means it will be re-enqueued to the destination queue when it's picked up.

```ruby
# Mark a specific Job to be rerouted by specifying its job ID
client.reroute("different_queue", :jid, some_job_id)

# Mark an entire job class to be rerouted
client.reroute("different_queue", :class, "SomeJobClass")
```

A job or job class can also be removed from rerouting for disposal via a corresponding API.

```ruby
# Unmark a specific Job to be rerouted by specifying its job ID
client.remove_rerouting("different_queue", :jid, some_job_id)

# Unmark an entire job class to be rerouted
client.remove_rerouting("different_queue", :class, "SomeJobClass")
```

### Clearing all rerouting

Clearing all reroutes marks can be done in one fell swoop as well.

```ruby
client.remove_rerouting_for_all
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hibachrach/sidekiq-rerouting. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hibachrach/sidekiq-rerouting/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sidekiq::Rerouting project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hibachrach/sidekiq-rerouting/blob/main/CODE_OF_CONDUCT.md).

[sidekiq]: https://sidekiq.org "Simple, efficient background jobs for Ruby."
