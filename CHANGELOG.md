## [Unreleased]

## [Unreleased]: # (Unreleased)

- Added support for Sidekiq Pro's Batch feature.
- **Breaking**: the `on_reroute` callback's `job` parameter is now the rerouted job instead of the original job.
    Meaning the `job["queue"]` will be the rerouted queue, not the original queue.

## [0.2.0] - 2025-09-22

- **Breaking**: Change configuration of middleware to work with `Sidekiq::Middleware::Chain` API

## [0.1.0] - 2025-09-22

- Initial release
