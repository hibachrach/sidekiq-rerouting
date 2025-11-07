# frozen_string_literal: true

require_relative "../rerouting"

module Sidekiq
  module Rerouting
    class BatchAPI
      def jobs_in(batch:)
        batch_api.new(batch).jobs do
          yield
        end
      end

      private

      def batch_api
        @batch_api ||= defined?(::Sidekiq::Batch) ? ::Sidekiq::Batch : NullBatchAPI
      end

      class NullBatchAPI
        def initialize(_batch_id)
        end

        def jobs
          yield
        end
      end
    end
  end
end
