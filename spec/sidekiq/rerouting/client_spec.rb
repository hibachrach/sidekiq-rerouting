# frozen_string_literal: true

require "sidekiq"
require "sidekiq/rerouting/client"

RSpec.describe Sidekiq::Rerouting::Client, :with_test_redis do
  subject(:client) { described_class.new }

  let(:bad_job) do
    {
      "jid" => "abcdef1234567890",
      "class" => "TillyScratchesTheCouchJob",
      "queue" => "original_queue"
    }
  end
  let(:bad_job2) do
    {
      "jid" => "babababa2468013579",
      "class" => "TillySwipesAtPassersByJob",
      "queue" => "original_queue"
    }
  end
  let(:good_job) do
    {
      "jid" => "9876543210fedcba",
      "class" => "TillyLeavesAToyMouseAtMyDoorJob",
      "queue" => "original_queue"
    }
  end

  describe "#reroute" do
    it "can reroute job by jid" do
      client.reroute("devious_queue", :jid, bad_job["jid"])
      expect(client.rerouting_destination(bad_job)).to eq("devious_queue")
    end

    it "can reroute by class" do
      client.reroute("devious_queue", :class, bad_job["class"])
      expect(client.rerouting_destination(bad_job)).to eq("devious_queue")
    end
  end

  describe "#remove_rerouting" do
    it "unsets the rerouting destination for the specified job" do
      client.reroute("devious_queue", :jid, bad_job["jid"])
      client.reroute("devious_queue", :jid, bad_job2["jid"])
      expect(client.rerouting_destination(bad_job)).to eq("devious_queue")
      expect(client.rerouting_destination(bad_job)).to eq("devious_queue")
      client.remove_rerouting(:jid, bad_job["jid"])
      expect(client.rerouting_destination(bad_job)).to be_nil
      expect(client.rerouting_destination(bad_job2)).to eq("devious_queue")
    end
  end

  describe "#remove_rerouting_for_all" do
    it "removes all specified markers" do
      client.reroute("devious_queue", :jid, bad_job["jid"])
      client.reroute("devious_queue", :jid, bad_job2["jid"])
      expect(client.rerouting_destination(bad_job)).to eq("devious_queue")
      expect(client.rerouting_destination(bad_job)).to eq("devious_queue")
      client.remove_rerouting_for_all
      expect(client.rerouting_destination(bad_job)).to be_nil
      expect(client.rerouting_destination(bad_job2)).to be_nil
    end
  end

  describe "#rerouting_markers" do
    it "returns all markers added" do
      client.reroute("queue1", :jid, bad_job["jid"])
      client.reroute("queue1", :jid, bad_job["jid"]) # To demonstrate idempotence
      client.reroute("queue2", :class, bad_job["class"])
      client.reroute("queue3", :class, bad_job2["class"])
      expect(client.rerouting_markers).to eq(
        {
          "jid:#{bad_job["jid"]}" => "queue1",
          "class:#{bad_job["class"]}" => "queue2",
          "class:#{bad_job2["class"]}" => "queue3"
        }
      )
    end
  end
end
