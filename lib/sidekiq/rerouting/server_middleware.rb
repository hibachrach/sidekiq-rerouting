# frozen_string_literal: true

require "sidekiq"
require_relative "../rerouting"

module Sidekiq
  module Rerouting
    class ServerMiddleware
      include ::Sidekiq::ServerMiddleware

      def initialize(opts = {})
        @client = opts.fetch(:client, Client.new)
        @on_reroute = opts.fetch(:on_reroute, nil)
      end

      def call(job_instance, job, queue)
        if job_instance && !job_instance.class.get_sidekiq_options.fetch("reroutable", true)
          yield
        elsif job_instance &&
            (rerouting_destination = client.rerouting_destination(job)) &&
            rerouting_destination != queue
          job_instance.class.client_push(job.merge("queue" => rerouting_destination))
          on_reroute&.call(job:, old_queue: queue, new_queue: rerouting_destination)
        else
          yield
        end
      end

      private

      attr_reader :client, :on_reroute
    end
  end
end
