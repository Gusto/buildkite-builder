module Buildkite
  module Converter
    module StepAttributes
      class SymbolizedArray < Abstract
        def parse
          raise ArgumentError, "Expecting a Array, got a '#{value.class}'" unless value.is_a?(Array)

          sub_output = value.map do |line|
            ":#{line}"
          end

          "#{key} #{sub_output.join(', ')}"
        end
      end
    end
  end
end

