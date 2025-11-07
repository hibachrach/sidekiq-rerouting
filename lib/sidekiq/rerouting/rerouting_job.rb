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

      def rerouted_destination
        return @rerouted_destination if defined?(@rerouted_destination)

        @rerouted_destination = client.rerouting_destination(job_payload)
      end

      def rerouted_from?(queue:)
        rerouted_destination && rerouted_destination != queue
      end

      private

      attr_reader :client, :job_instance, :job_payload
    end
  end
end
