# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Retry
        def automatically_retry(status:, limit:)
          retry_value = get(:retry)&.[](:automatic)

          unless retry_value.is_a?(Array)
            retry_value = []
            self.retry(automatic: retry_value)
          end

          retry_value.push(exit_status: status, limit: limit)
        end
      end
    end
  end
end
