# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module DependsOn
        def depends_on(*values)
          values.flatten.each { |value| super(value) }
        end
      end
    end
  end
end
