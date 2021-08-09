# frozen_string_literal: true

module Buildkite
  module Builder
    module DSL
      module Features
        module Wait
          def wait(*args)
            step = add(Pipelines::Steps::Wait, &block)
            step.wait(nil)
            attributes.each do |key, value|
              step.set(key, value)
            end
            step
          end
        end
      end
    end
  end
end
