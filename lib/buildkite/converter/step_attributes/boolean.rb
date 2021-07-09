module Buildkite
  module Converter
    module StepAttributes
      class Boolean < Abstract
        def parse
          raise ArgumentError, "Expecting a TrueClass or FalseClass, got a '#{value.class}'" unless [TrueClass, FalseClass].include?(value.class)

          "#{key} #{value}"
        end
      end
    end
  end
end
