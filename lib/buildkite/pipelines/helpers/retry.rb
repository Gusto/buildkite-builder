# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Retry
        def automatic_retry_on(exit_status:, limit:)
          retry_value = get(:retry) || set(:retry, {})

          unless retry_value[:automatic].is_a?(Array)
            retry_value[:automatic] = []
          end

          retry_value[:automatic].push(exit_status: exit_status, limit: limit)
        end

        def automatic_retry(enabled)
          retry_value = get(:retry) || set(:retry, {})
          retry_value[:automatic] = enabled
        end

        def manual_retry(allowed, reason: nil, permit_on_passed: nil)
          retry_value = get(:retry) || set(:retry, {})
          retry_value[:manual] = { allowed: allowed }
          retry_value[:manual][:reason] = reason unless reason.nil?
          retry_value[:manual][:permit_on_passed] = permit_on_passed unless permit_on_passed.nil?
        end
      end
    end
  end
end
