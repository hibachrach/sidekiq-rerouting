# frozen_string_literal: true

require "sidekiq"
require_relative "../rerouting"
require_relative "rerouting_job"

module Sidekiq
  module Rerouting
    class ServerMiddleware
      include ::Sidekiq::ServerMiddleware

      def initialize(opts = {})
        @client = opts.fetch(:client, Client.new)
        @on_reroute = opts.fetch(:on_reroute, nil)
      end

      def call(job_instance, job_payload, queue)
        job = ReroutingJob.new(job_instance:, job_payload:, client:)

        if job.reroutable? && job.rerouted_from?(queue:)
          reroute(sidekiq_client: job_instance.class, job: job)
        else
          yield
        end
      end

      private

      attr_reader :client, :on_reroute

      def reroute(sidekiq_client:, job:)
        sidekiq_client.client_push(job.rerouted_playload)

        on_reroute&.call(job: job.rerouted_playload, old_queue: job.original_queue, new_queue: job.rerouted_queue)
      end
    end
  end
end
