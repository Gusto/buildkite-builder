module Buildkite
  module Converter
    module StepAttributes
      class ArrayType < Abstract
        def parse
          raise ArgumentError, "Expecting a Array, got a '#{value.class}'" unless value.is_a?(Array)

          string_start = "#{key}: %w("
          string_end = "),"

          sub_output = value.map do |line|
            "  #{line}"
          end

          sub_output.prepend(string_start)
          sub_output.append(string_end)

          sub_output.join("\n")
        end
      end
    end
  end
end

