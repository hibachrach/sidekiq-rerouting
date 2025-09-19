# frozen_string_literal: true

require "sidekiq"

module Sidekiq
  module Rerouting
    # A client for marking enqueued jobs for rerouting. A rerouted job is one
    # that is re-enqueued as is to a different destination queue.
    #
    # This task is accomplished with "markers": A job can be "marked" for
    # rerouting. This means that a "marker" (a job id/jid or class name) can
    # be formatted and then added to the relevant target set.
    #
    # When a worker picks up the job, the corresponding `ServerMiddleware` will
    # then re-enqueue the job to the destination queue and exit early (skipping
    # execution).
    class Client
      REDIS_TARGET_HASH = "sidekiq-rerouting:rerouting_targets"

      # The types of markers that are allowed for identifying jobs.
      # NOTE: The order of this array is important--jobs are matched in
      # order, so `jid` takes priority over `class`
      ALLOWED_MARKER_TYPES = %i[jid class].freeze

      def initialize(sidekiq_api = ::Sidekiq)
        @sidekiq_api = sidekiq_api
      end

      # @param target_queue [String] The queue to which the job should be rerouted
      # @param marker_type [:jid, :class] The type of marker being used to identify the job
      # @param string marker [String] The identifying value of the marker
      def reroute(target_queue, marker_type, marker)
        redis do |conn|
          formatted = formatted_marker(marker_type, marker)
          conn.hset(REDIS_TARGET_HASH, formatted, target_queue)
        end
      end

      # @param marker_type [:jid, :class] The type of marker being used to identify the job
      # @param string marker [String] The identifying value of the marker
      def remove_rerouting(marker_type, marker)
        redis do |conn|
          conn.hdel(REDIS_TARGET_HASH, formatted_marker(marker_type, marker))
        end
      end

      def remove_rerouting_for_all
        redis do |conn|
          conn.del(REDIS_TARGET_HASH)
        end
      end

      # @returns [Hash<String,String>] A hash of all markers and their destination queues
      def rerouting_markers
        redis do |conn|
          conn.hgetall(REDIS_TARGET_HASH)
        end
      end

      # @retruns [String, nil] The destination queue for the given job, or nil if not marked for rerouting
      def rerouting_destination(job)
        redis do |conn|
          conn.hmget(REDIS_TARGET_HASH, formatted_markers(job))
        end.find(&:itself)
      end

      private

      def redis(&blk)
        sidekiq_api.redis(&blk)
      end

      # @return [Array] A list of identifying formatted_markers/features which
      #                 indicates a job is targeted for rerouting.
      def formatted_markers(job)
        ALLOWED_MARKER_TYPES.map do |marker_type|
          formatted_marker_for_job(marker_type, job)
        end.compact
      end

      # @returns the formatted marker that would be in Redis if this job has
      # been targeted
      def formatted_marker_for_job(marker_type, job)
        formatted_marker(marker_type, job[marker_type.to_s])
      end

      # @returns the marker as it is stored in Redis
      def formatted_marker(marker_type, marker)
        return nil if marker.nil?
        raise ArgumentError unless ALLOWED_MARKER_TYPES.include?(marker_type.to_sym)

        "#{marker_type}:#{marker}"
      end

      attr_reader :sidekiq_api
    end
  end
end
