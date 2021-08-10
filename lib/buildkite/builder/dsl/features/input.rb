module Buildkite
  module Builder
    module Dsl
      module Features
        module Input
          def input(template = nil, **args, &block)
            add_to_steps(Pipelines::Steps::Input, template, **args, &block)
          end
        end
      end
    end
  end
end
