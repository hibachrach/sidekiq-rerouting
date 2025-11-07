# frozen_string_literal: true

require_relative "../rerouting"

module Sidekiq
  module Rerouting
    class ReroutingJob
      def initialize(job_instance:, job_payload:, client: Client.new)
        @client = client
        @job_instance = job_instance
        @job_payload = job_payload
      end

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

      def original_queue
        job_payload["queue"]
      end

      private

      attr_reader :client, :job_instance, :job_payload
    end
  end
end
