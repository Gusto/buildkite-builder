module Buildkite
  module Builder
    module Dsl
      module Features
        module Trigger
          def trigger(template = nil, **args, &block)
            Helpers.add_to_steps(_context, Pipelines::Steps::Trigger, template, **args, &block)
          end
        end
      end
    end
  end
end
