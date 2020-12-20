# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module BlockedState
        # blocked_state can be one of: passed, failed, running
        # https://buildkite.com/docs/pipelines/block-step#block-step-attributes
        VALID_VALUES = Set.new(['passed', 'failed', 'running']).freeze

        def blocked_state(arg)
          arg = arg.to_s

          if VALID_VALUES.include?(arg)
            super(arg)
          else
            raise ArgumentError, "Cannot set blocked_state to #{arg}, must be one of: #{VALID_VALUES.to_a.join(', ')}"
          end
        end
      end
    end
  end
end
