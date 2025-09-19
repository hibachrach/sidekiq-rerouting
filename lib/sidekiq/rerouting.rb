# frozen_string_literal: true

require_relative "rerouting/version"
require_relative "rerouting/client"
require_relative "rerouting/server_middleware"

module Sidekiq
  # Namespace for everything related to Sidekiq job rerouting: the processing
  # of putting jobs' markers (i.e. identifying features) into a Redis hash so
  # they can be "rerouted" (re-enqueued into a different queue during pickup).
  module Rerouting
  end
end
