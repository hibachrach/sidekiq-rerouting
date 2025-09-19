# frozen_string_literal: true

require "sidekiq"
require "sidekiq/rerouting/server_middleware"
require "sidekiq/rerouting/client"
require "timecop"

module Sidekiq
  module Rerouting
    RSpec.describe ServerMiddleware, :with_test_redis do
      subject(:middleware) do
        described_class.new(&on_reroute).tap { |m| m.config = ::Sidekiq.default_configuration }
      end

      let(:client) { Client.new }
      let(:serialized_job) do
        ServerMiddlewareTestCustomJob.perform_async("foo", 2, "baz")
        ServerMiddlewareTestCustomJob.jobs.first
      end
      let(:on_reroute_sentinel) { double("on reroute sentinel", call: nil) }
      let(:on_reroute) do
        ->(*args, **kwargs) { on_reroute_sentinel.call(*args, **kwargs) }
      end
      let(:job_perform_sentinel) { double("job perform sentinel", blah: nil) }

      around do |example|
        Timecop.freeze(Time.now, &example)
      end

      it "enqueues the job, exits early, and calls the `on_reroute` callback if job class has been marked for rerouting" do
        Client.new.reroute("a_different_queue", :class, ServerMiddlewareTestCustomJob.name)
        middleware.call(ServerMiddlewareTestCustomJob.new, serialized_job, "within_50_years") do
          job_perform_sentinel.blah
        end
        expect(on_reroute_sentinel).to have_received(:call).with(job: serialized_job, old_queue: "within_50_years",
          new_queue: "a_different_queue")
        expect(job_perform_sentinel).not_to have_received(:blah)
        expected_job = serialized_job.dup.tap do |j|
          j["queue"] = "a_different_queue"
        end
        expect(Sidekiq::Queues["a_different_queue"]).to eq([expected_job])
      end

      it "just yields if job has been designated as non-reroutable" do
        serialized_job = begin
          ServerMiddlewareTestNonReroutableJob.perform_async("foo", 2, "baz")
          ServerMiddlewareTestNonReroutableJob.jobs.first
        end
        Client.new.reroute("a_different_queue", :class, ServerMiddlewareTestNonReroutableJob.name)
        middleware.call(ServerMiddlewareTestNonReroutableJob.new, serialized_job, "within_50_years") do
          job_perform_sentinel.blah
        end
        expect(on_reroute_sentinel).not_to have_received(:call)
        expect(job_perform_sentinel).to have_received(:blah)
        expect(Sidekiq::Queues["a_different_queue"]).to be_empty
      end

      it "just yields if job has not be rerouted" do
        middleware.call(ServerMiddlewareTestCustomJob.new, serialized_job, "within_50_years") do
          job_perform_sentinel.blah
        end
        expect(on_reroute_sentinel).not_to have_received(:call)
        expect(job_perform_sentinel).to have_received(:blah)
        expect(Sidekiq::Queues["a_different_queue"]).to be_empty
      end
    end

    class ServerMiddlewareTestCustomJob
      include ::Sidekiq::Job

      sidekiq_options queue: :within_50_years

      def perform(foo, bar, baz)
      end
    end

    class ServerMiddlewareTestNonReroutableJob
      include ::Sidekiq::Job

      sidekiq_options queue: :within_50_years, reroutable: false

      def perform(foo, bar, baz)
      end
    end
  end
end
