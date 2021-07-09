module Buildkite
  module Converter
    module StepAttributes
      class Wait < Abstract
        VALID_VALUE_TYPES = [NilClass].freeze

        def parse
          unless VALID_VALUE_TYPES.include?(value.class)
            raise ArgumentError, "Expecting value to have a type of [#{VALID_VALUE_TYPES.join(', ')}], got a #{value.class}."
          end

          'wait'
        end
      end
    end
  end
end

