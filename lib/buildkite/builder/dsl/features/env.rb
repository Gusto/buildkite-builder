# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      module Features
        module Env
          def env(*args)
            if args.first.is_a?(Hash)
              _context.env.merge!(args.first.transform_keys(&:to_s))
            else
              raise ArgumentError, 'value must be hash'
            end
          end
        end
      end
    end
  end
end
