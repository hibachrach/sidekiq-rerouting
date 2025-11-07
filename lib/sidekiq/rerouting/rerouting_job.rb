# frozen_string_literal: true

require_relative "../rerouting"
require_relative "batch_api"

module Sidekiq
  module Rerouting
    class ReroutingJob
      def initialize(job_instance:, job_payload:, client: Client.new, batch_api: BatchAPI.new)
        @batch_api = batch_api
        @client = client
        @job_instance = job_instance
        @job_payload = job_payload
        @original_queue = job_payload["queue"]
      end

      attr_reader :original_queue

      def reroutable?
        job_instance && job_instance.class.get_sidekiq_options.fetch("reroutable", true)
      end

      def rerouted_from?(queue:)
        rerouted_queue && rerouted_queue != queue
      end

      def rerouted_playload
        job_payload.merge("queue" => rerouted_queue)
      end

      def rerouted_queue
        return @rerouted_queue if defined?(@rerouted_queue)

        @rerouted_queue = client.rerouting_destination(job_payload)
      end

      def within_batch_maybe
        batch_id = job_payload["bid"]

        return yield unless batch_id

        batch_api.jobs_in(batch: batch_id) do
          yield
        end
      end

      private

      attr_reader :batch_api, :client, :job_instance, :job_payload
    end
  end
end
