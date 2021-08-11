module Buildkite
  module Builder
    module Dsl
      module Features
        module Wait
          def wait(attributes = {}, &block)
            step = Helpers.add_to_steps(_context, Pipelines::Steps::Wait, &block)
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
