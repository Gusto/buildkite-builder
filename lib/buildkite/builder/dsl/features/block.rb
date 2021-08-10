module Buildkite
  module Builder
    module Dsl
      module Features
        module Block
          def block(template = nil, **args, &block)
            add_to_steps(Pipelines::Steps::Block, template, **args, &block)
          end
        end
      end
    end
  end
end
