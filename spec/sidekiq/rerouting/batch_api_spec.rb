# frozen_string_literal: true

require "sidekiq"
require "sidekiq/rerouting/batch_api"

module Sidekiq
  module Rerouting
    RSpec.describe BatchAPI do
      describe "#jobs_in" do
        subject(:batch_api) { BatchAPI.new }

        context "when Sidekiq::Batch is defined" do
          let(:batch_class) { class_double("Sidekiq::Batch") }
          let(:batch_instance) { instance_double("Sidekiq::Batch") }

          before do
            stub_const("Sidekiq::Batch", batch_class)
            allow(batch_class).to receive(:new).with("batch_id") { batch_instance }
            allow(batch_instance).to receive(:jobs) { |&block| block.call }
          end

          it "yields within the batch context" do
            expect do |b|
              batch_api.jobs_in(batch: "batch_id", &b)
            end.to yield_control

            expect(batch_instance).to have_received(:jobs)
          end
        end

        context "when Sidekiq::Batch is not defined" do
          let(:batch_api) { BatchAPI.new }

          before do
            hide_const("Sidekiq::Batch")
          end

          it "yields without error" do
            expect do |b|
              batch_api.jobs_in(batch: "batch_id", &b)
            end.to yield_control
          end
        end
      end
    end
  end
end
