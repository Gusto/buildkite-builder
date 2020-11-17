# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Skip
        # A helper method to see if the step is skipped.
        # Skipped steps are `true` or a non-empty string.
        def skipped?
          get(:skip) != false && !get(:skip).to_s.empty?
        end
      end
    end
  end
end
