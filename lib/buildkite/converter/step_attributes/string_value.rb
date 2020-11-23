module Buildkite
  module Converter
    module StepAttributes
      class StringValue < Abstract
        def parse
          raise ArgumentError, "Expecting a String, got a '#{value.class}'" unless value.is_a?(String)

          "#{key} :#{value}"
        end
      end
    end
  end
end
