module Buildkite
  module Builder
    module Extensions
      class Use < Extension
        dsl do
          def use(extension_class, **args)
            context.use(extension_class, **args)
          end
        end
      end
    end
  end
end
