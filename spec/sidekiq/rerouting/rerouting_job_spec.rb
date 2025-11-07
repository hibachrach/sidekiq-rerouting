# frozen_string_literal: true

require "sidekiq"
require "sidekiq/rerouting/rerouting_job"

module Sidekiq
  module Rerouting
    RSpec.describe ReroutingJob do
      let(:client) { instance_double(Client) }

      describe "#reroutable?" do
        it "is true if the job class is reroutable" do
          job = ReroutingJob.new(job_instance: ReroutingJobTestJob.new, job_payload: {}, client: client)

          expect(job).to be_reroutable
        end

        it "is false if the job class is not reroutable" do
          job = ReroutingJob.new(job_instance: ReroutingJobTestNonReroutableJob.new, job_payload: {}, client: client)

          expect(job).not_to be_reroutable
        end

        it "is false if the job_instance is nil" do
          job = ReroutingJob.new(job_instance: nil, job_payload: {}, client: client)

          expect(job).not_to be_reroutable
        end
      end

      describe "#rerouted_queue", :with_test_redis do
        let(:job) { ReroutingJob.new(job_instance: ReroutingJobTestJob.new, job_payload: payload, client: client) }
        let(:client) { Client.new }
        let(:payload) do
          ReroutingJobTestJob.perform_async("foo", 2, "baz")
          ReroutingJobTestJob.jobs.first
        end

        it "pulls the rerouted destination from redis" do
          client.reroute("new_queue", :class, ReroutingJobTestJob.name)

          expect(job.rerouted_queue).to eq("new_queue")
        end

        it "caches the rerouted destination" do
          allow(client).to receive(:rerouting_destination).with(payload) { nil }

          expect(job.rerouted_queue).to be_nil
          expect(job.rerouted_queue).to be_nil
          expect(client).to have_received(:rerouting_destination).once
        end
      end

      describe "#rerouted_from?" do
        let(:job) { ReroutingJob.new(job_instance: ReroutingJobTestJob.new, job_payload: payload, client: client) }
        let(:payload) { {} }

        it "is true if the rerouted destination differs from the current queue" do
          allow(client).to receive(:rerouting_destination).with(payload) { "different_queue" }

          expect(job).to be_rerouted_from(queue: "original_queue")
        end

        it "is false if the rerouted destination is the same as the current queue" do
          allow(client).to receive(:rerouting_destination).with(payload) { "original_queue" }

          expect(job).not_to be_rerouted_from(queue: "original_queue")
        end

        it "is false if there is no rerouted destination" do
          allow(client).to receive(:rerouting_destination).with(payload) { nil }

          expect(job).not_to be_rerouted_from(queue: "original_queue")
        end
      end
    end

    class ReroutingJobTestJob
      include Sidekiq::Job

      sidekiq_options queue: :within_50_years

      def perform(foo, bar, baz)
      end
    end

    class ReroutingJobTestNonReroutableJob
      include Sidekiq::Job

      sidekiq_options queue: :within_50_years, reroutable: false

      def perform(foo, bar, baz)
      end
    end
  end
end
