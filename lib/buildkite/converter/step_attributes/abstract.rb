module Buildkite
  module Converter
    module StepAttributes
      class Abstract
        class << self
          def parse(key, value)
            new(key, value).parse
          end
        end
        attr_reader :key, :value

        def initialize(key, value)
          @key = key
          @value = value
        end

        def parse
          raise NotImplementedError
        end
      end
    end
  end
end

