# frozen_string_literal: true

require "sidekiq"
require "sidekiq/rerouting/router"

module Sidekiq
  module Rerouting
    RSpec.describe Router do
      let(:client) { instance_double(Client) }

      describe "#reroutable?" do
        it "is true if the job class is reroutable" do
          router = Router.new(job_instance: ReroutingJobTestJob.new, job_payload: {}, client: client)

          expect(router).to be_reroutable
        end

        it "is false if the job class is not reroutable" do
          router = Router.new(job_instance: ReroutingJobTestNonReroutableJob.new, job_payload: {}, client: client)

          expect(router).not_to be_reroutable
        end

        it "is false if the job_instance is nil" do
          router = Router.new(job_instance: nil, job_payload: {}, client: client)

          expect(router).not_to be_reroutable
        end
      end

      describe "#rerouted_queue", :with_test_redis do
        let(:router) { Router.new(job_instance: ReroutingJobTestJob.new, job_payload: payload, client: client) }
        let(:client) { Client.new }
        let(:payload) do
          ReroutingJobTestJob.perform_async("foo", 2, "baz")
          ReroutingJobTestJob.jobs.first
        end

        it "pulls the rerouted destination from redis" do
          client.reroute("new_queue", :class, ReroutingJobTestJob.name)

          expect(router.rerouted_queue).to eq("new_queue")
        end

        it "caches the rerouted destination" do
          allow(client).to receive(:rerouting_destination).with(payload) { nil }

          expect(router.rerouted_queue).to be_nil
          expect(router.rerouted_queue).to be_nil
          expect(client).to have_received(:rerouting_destination).once
        end
      end

      describe "#rerouted_from?" do
        let(:router) { Router.new(job_instance: ReroutingJobTestJob.new, job_payload:, client:) }
        let(:job_payload) { {} }

        it "is true if the rerouted destination differs from the current queue" do
          allow(client).to receive(:rerouting_destination).with(job_payload) { "different_queue" }

          expect(router).to be_rerouted_from(queue: "original_queue")
        end

        it "is false if the rerouted destination is the same as the current queue" do
          allow(client).to receive(:rerouting_destination).with(job_payload) { "original_queue" }

          expect(router).not_to be_rerouted_from(queue: "original_queue")
        end

        it "is false if there is no rerouted destination" do
          allow(client).to receive(:rerouting_destination).with(job_payload) { nil }

          expect(router).not_to be_rerouted_from(queue: "original_queue")
        end
      end

      describe "within_batch_maybe" do
        let(:router) { Router.new(job_instance: ReroutingJobTestJob.new, job_payload:, client:, batch_api:) }
        let(:job_payload) { {} }
        let(:batch_api) { instance_double(BatchAPI, jobs_in: :ok) }

        it "yields directly if there is no batch ID" do
          yielded = false
          router.within_batch_maybe do
            yielded = true
          end

          expect(yielded).to be true
          expect(batch_api).not_to have_received(:jobs_in)
        end

        it "defers to the BatchAPI if there is a batch ID" do
          bid = "some_batch_id"
          job_payload["bid"] = bid
          allow(batch_api).to receive(:jobs_in).with(batch: bid).and_yield

          yielded = false
          router.within_batch_maybe do
            yielded = true
          end

          expect(yielded).to be true
          expect(batch_api).to have_received(:jobs_in).with(batch: "some_batch_id")
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
