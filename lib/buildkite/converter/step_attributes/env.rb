module Buildkite
  module Converter
    module StepAttributes
      class Env < Abstract
        def parse
          env_pairs = value
          string_start = "env("
          string_end = ")"

          env = env_pairs.inject([]) do |output, (k, v)|
            output << "  #{k}: '#{v}'"
          end.join(",\n")

          output = [env]
          output.prepend(string_start)
          output.append(string_end)

          output.join("\n")
        end
      end
    end
  end
end

