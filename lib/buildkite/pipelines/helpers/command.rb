# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Command
        def command(*values)
          return super if values.empty?

          values.flatten.each do |value|
            if value == :noop
              super('true')
            else
              super(value)
            end
          end
        end
      end
    end
  end
end
