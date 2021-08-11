module Buildkite
  module Builder
    module Dsl
      module Features
        module Input
          def input(template = nil, **args, &block)
            Helpers.add_to_steps(_context, Pipelines::Steps::Input, template, **args, &block)
          end
        end
      end
    end
  end
end
