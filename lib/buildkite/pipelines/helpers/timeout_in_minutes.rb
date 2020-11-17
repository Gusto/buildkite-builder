# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module TimeoutInMinutes
        def timeout(*args)
          timeout_in_minutes(*args)
        end

        def timeout?(*args)
          timeout_in_minutes?(*args)
        end
      end
    end
  end
end
