module Buildkite
  module Converter
    module StepAttributes
      class Agents < Abstract
        def parse
          raise ArgumentError, "Expecting a Hash, got a '#{value.class}'" unless value.is_a?(Hash)

          queue = value.fetch('queue')
          "agents queue: :#{queue}"
        end
      end
    end
  end
end
