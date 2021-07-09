module Buildkite
  module Converter
    module StepAttributes
      class Build < Abstract
        def parse
          raise ArgumentError, "Expecting a Hash, got a '#{value.class}'" unless value.is_a?(Hash)

          build_config = value
          string_start = "build("
          string_end = ")"

          parsed_config = PluginConfigParser.new(build_config, 1).parse

          output = [parsed_config]
          output.prepend(string_start)
          output.append(string_end)

          output.join("\n")
        end
      end
    end
  end
end
