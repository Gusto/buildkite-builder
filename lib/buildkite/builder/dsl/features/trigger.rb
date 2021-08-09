module Buildkite
  module Builder
    module DSL
      module Features
        module Trigger
          def trigger(template = nil, **args, &block)
            add_to_steps(Pipelines::Steps::Trigger, template, **args, &block)
          end
        end
      end
    end
  end
end