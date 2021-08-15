module Buildkite
  module Builder
    module Extensions
      class Env < Extension
        dsl do
          def use(extension_class, **args)
            context.register(extension_class, **args)
          end
        end
      end
    end
  end
end
