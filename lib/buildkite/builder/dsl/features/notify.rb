# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      module Features
        module Notify
          def notify(*args)
            if args.first.is_a?(Hash)
              _context.notify.push(args.first.transform_keys(&:to_s))
            else
              raise ArgumentError, 'value must be hash'
            end
          end
        end
      end
    end
  end
end
