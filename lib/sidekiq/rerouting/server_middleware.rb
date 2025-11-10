# frozen_string_literal: true

require "sidekiq"
require_relative "../rerouting"
require_relative "router"

module Sidekiq
  module Rerouting
    class ServerMiddleware
      include ::Sidekiq::ServerMiddleware

      def initialize(opts = {})
        @client = opts.fetch(:client, Client.new)
        @on_reroute = opts.fetch(:on_reroute, nil)
      end

      def call(job_instance, job_payload, queue)
        router = Router.new(job_instance:, job_payload:, client:)

        if router.reroutable? && router.rerouted_from?(queue:)
          router.within_batch_maybe do
            reroute(sidekiq_client: job_instance.class, router: router)
          end
        else
          yield
        end
      end

      private

      attr_reader :client, :on_reroute

      def reroute(sidekiq_client:, router:)
        sidekiq_client.client_push(router.rerouted_playload)

        on_reroute&.call(job: router.rerouted_playload, old_queue: router.original_queue, new_queue: router.rerouted_queue)
      end
    end
  end
end
