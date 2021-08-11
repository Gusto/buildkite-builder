module Buildkite
  module Builder
    module Dsl
      module Features
        module Block
          def block(template = nil, **args, &block)
            Helpers.add_to_steps(_context, Pipelines::Steps::Block, template, **args, &block)
          end
        end
      end
    end
  end
end
