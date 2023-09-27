# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module DependsOn
        def depends_on(*values)
          return super if values.empty?

          values.flatten.each { |value| super(value) }
        end
      end
    end
  end
end
