# Sidekiq::Rerouting

[![CI](https://github.com/hibachrach/sidekiq-rerouting/actions/workflows/main.yml/badge.svg)](https://github.com/hibachrach/sidekiq-rerouting/actions)

A [Sidekiq][sidekiq] extension to set Sidekiq jobs to be rerouted to a different queue based on the job ID or job class.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add sidekiq-rerouting
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install sidekiq-rerouting
```

## Usage

From a console (Rails console, or the like) you need a `Sidekiq::Rerouting::Client` instance, which is used to `#reroute` a job, or job class to be disposed.

```ruby
client = Sidekiq::Rerouting::Client.new
```

### Marking to reroute

A job marked to be rerouted means it will be re-enqueued to the destination queue when it's picked up.

```ruby
# Mark a specific Job to be rerouted by specifying its job ID
client.reroute("different_queue", :jid, some_job_id)

# Mark an entire job class to be rerouted
client.reroute("different_queue", :class, "SomeJobClass")
```

A job or job class can also be removed from rerouting via a corresponding API. This only takes effects for jobs enqueued after the API call.
Reroute the jobs back to its original queue to affect the previously rerouted jobs still in the queue.

```ruby
# Unmark a specific Job to be rerouted by specifying its job ID
client.remove_rerouting(:jid, some_job_id)

# Unmark an entire job class to be rerouted
client.remove_rerouting(:class, "SomeJobClass")

# Force previously rerouted job class/jid to its original queue
client.reroute("original_queue", :jid, some_job_id)
client.reroute("original_queue", :class, "SomeJobClass")
```

### Clearing all rerouting

Clearing all reroutes marks can be done in one fell swoop as well.

```ruby
client.remove_rerouting_for_all
```

## Configuration

With `sidekiq-rerouting` installed, [register its Sidekiq server middleware][sidekiq-register-middleware].
Typically this is done via `config/initializers/sidekiq.rb` in a Rails app.

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Rerouting::ServerMiddleware
  end
end
```

This piece of middleware checks each job, after it's been dequeued, but before its `#perform` has been called, to see if it should be rerouted.
If the job is marked for rerouting (by job ID or job class), a new job (with the same job ID) is enqueued into the intended destination and the current job exits early.

### Callback

If you'd like to do something when a job is rerouted,
you can optionally pass in an object that responds to `.call` (like a `Proc`) when adding the middleware:

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add(Sidekiq::Rerouting::ServerMiddleware, on_reroute: -> { |job:, old_queue:, new_queue:|
      puts "Job with jid=#{job["jid"]} was rerouted from #{old_queue} to #{new_queue}"
    })
  end
end
```

It yields the following keyword arguments:

- `job`: the serialized job that is being rerouted; see [Sidekiq's docs][job-format] for more details.
- `old_queue`: the queue _from which_ the job is being rerouted.
- `new_queue`: the queue _to which_ the job is being rerouted.

### Non-Reroutable Jobs

By default all Jobs are reroutable.
However, checking if a specific job should be rerouted is not free; it requires round trip(s) to Redis.
Therefore, you might want to make some jobs non-reroutable to avoid these extra round trips.
Or because there are some Jobs that simply should never be rerouted for… _reasons_.

This is done via a job's `sidekiq_options`.

```ruby
sidekiq_options reroutable: false
```

With that in place, the server middleware will ignore the Job, and pass it down the middleware Chain.
No extra Redis calls, no funny business.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hibachrach/sidekiq-rerouting. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hibachrach/sidekiq-rerouting/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Sidekiq::Rerouting project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hibachrach/sidekiq-rerouting/blob/main/CODE_OF_CONDUCT.md).

## See Also

- [`sidekiq-disposal`][sidekiq-disposal]

[sidekiq]: https://sidekiq.org "Simple, efficient background jobs for Ruby."
[sidekiq-disposal]: https://github.com/hibachrach/sidekiq-disposal "A Sidekiq extension to mark Sidekiq jobs to be disposed of."
[sidekiq-register-middleware]: https://github.com/sidekiq/sidekiq/wiki/Middleware#registering-middleware "Registering Sidekiq Middleware"
[job-format]: https://github.com/sidekiq/sidekiq/wiki/Job-Format "How Sidekiq jobs are serialized"
