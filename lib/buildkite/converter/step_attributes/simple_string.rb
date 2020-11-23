module Buildkite
  module Converter
    module StepAttributes
      class SimpleString < Abstract
        def parse
          "#{key} '#{value}'"
        end
      end
    end
  end
end

