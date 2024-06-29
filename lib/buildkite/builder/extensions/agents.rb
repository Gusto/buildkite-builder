module Buildkite
  module Builder
    module Extensions
      class Agents < Extension
        def prepare
          context.data.agents = {}
        end

        dsl do
          def agents(*args)
            if args.first.is_a?(Hash)
              context.data.agents.merge!(args.first.transform_keys(&:to_s))
            else
              raise ArgumentError, 'value must be hash'
            end
          end
        end
      end
    end
  end
end
