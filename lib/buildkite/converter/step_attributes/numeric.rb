module Buildkite
  module Converter
    module StepAttributes
      class Numeric < Abstract
        def parse
          "#{key} #{value}"
        end
      end
    end
  end
end

