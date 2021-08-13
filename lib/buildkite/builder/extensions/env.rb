module Buildkite
  module Builder
    module Extensions
      class Env < Extension
        def prepare
          context.data[:env] = {}
        end

        dsl do
          def env(*args)
            if args.first.is_a?(Hash)
              context.data[:env].merge!(args.first.transform_keys(&:to_s))
            else
              raise ArgumentError, 'value must be hash'
            end
          end
        end
      end
    end
  end
end
