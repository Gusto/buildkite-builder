module Buildkite
  module Builder
    module Extensions
      class Use < Extension
        dsl do
          def use(extension_class, **args, &block)
            context.use(extension_class, **args, &block)
          end
        end
      end
    end
  end
end
