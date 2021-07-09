module Buildkite
  module Converter
    module StepAttributes
      class Timeout < Abstract
        def parse
          "timeout #{value}"
        end
      end
    end
  end
end

