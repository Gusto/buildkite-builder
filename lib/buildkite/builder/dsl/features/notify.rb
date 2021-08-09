# frozen_string_literal: true

module Buildkite
  module Builder
    module DSL
      module Features
        module Notify
          def notify(*args)
            data[:notify] ||= []

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
