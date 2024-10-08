# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module DependsOn
        def depends_on(*values)
          values.any? ? super(values.flatten) : super()
        end
      end
    end
  end
end
