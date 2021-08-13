module Buildkite
  module Builder
    module Extensions
      class Notify < Extension
        def prepare
          context.data[:notify] = []
        end

        dsl do
          def notify(*args)
            if args.first.is_a?(Hash)
              context.data[:notify].push(args.first.transform_keys(&:to_s))
            else
              raise ArgumentError, 'value must be hash'
            end
          end
        end
      end
    end
  end
end
