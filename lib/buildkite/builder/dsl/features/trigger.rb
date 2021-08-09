module Buildkite
  module Builder
    module DSL
      module Features
        module Trigger
          def trigger(template = nil, **args, &block)
            add_to_steps(Pipelines::Steps::Trigger, &block)
          end
        end
      end
    end
  end
end
