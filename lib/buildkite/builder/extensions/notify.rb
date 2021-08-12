module Buildkite
  module Builder
    module Extensions
      class Notify < Extension
        dsl do
          def notify(*args)
            if args.first.is_a?(Hash)
              data[:notify].push(args.first.transform_keys(&:to_s))
            else
              raise ArgumentError, 'value must be hash'
            end
          end
        end
      end
    end
  end
end
