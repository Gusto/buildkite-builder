# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module SoftFail
        def soft_fail_on_status(*statuses)
          statuses.each do |status|
            soft_fail(exit_status: status)
          end
        end
      end
    end
  end
end
