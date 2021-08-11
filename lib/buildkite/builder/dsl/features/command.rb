module Buildkite
  module Builder
    module Dsl
      module Features
        module Command
          def command(template = nil, **args, &block)
            Helpers.add_to_steps(_context, Pipelines::Steps::Command, template, **args, &block)
          end
        end
      end
    end
  end
end
