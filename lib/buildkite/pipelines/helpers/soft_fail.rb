# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module SoftFail
        def soft_fail(*value)
          # soft_fail can be an array of exit_statuses or true
          # https://buildkite.com/docs/pipelines/command-step#soft-fail-attributes

          if value.first == true
            current = get('soft_fail')

            if current.is_a?(Array)
              raise ArgumentError, "Cannot set soft_fail to true when it's already an array.\nsoft_fail: #{current}"
            else
              set('soft_fail', true)
            end
          else
            super
          end
        end

        def soft_fail_on_status(*statuses)
          statuses.each do |status|
            soft_fail(exit_status: status)
          end
        end
      end
    end
  end
end
