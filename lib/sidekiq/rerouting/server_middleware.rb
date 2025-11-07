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
          job_instance.class.client_push(job_payload.merge("queue" => job.rerouted_destination))

          on_reroute&.call(job: job_payload, old_queue: queue, new_queue: job.rerouted_destination)
        else
          yield
        end
      end

      private

      attr_reader :client, :on_reroute
    end
  end
end
