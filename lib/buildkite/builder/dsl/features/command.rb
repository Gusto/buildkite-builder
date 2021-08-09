module Buildkite
  module Builder
    module DSL
      module Features
        module Command
          def command(template = nil, **args, &block)
            add_to_steps(Pipelines::Steps::Command, template, **args, &block)
          end
        end
      end
    end
  end
end
