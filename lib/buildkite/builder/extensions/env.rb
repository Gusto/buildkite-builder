module Buildkite
  module Builder
    module Extensions
      class Env < Extension
        dsl do
          def env(*args)
            if args.first.is_a?(Hash)
              data[:env].merge!(args.first.transform_keys(&:to_s))
            else
              raise ArgumentError, 'value must be hash'
            end
          end
        end
      end
    end
  end
end
