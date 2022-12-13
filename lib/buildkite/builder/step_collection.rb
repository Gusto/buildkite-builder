module Buildkite
  module Builder
    class StepCollection
      attr_reader :steps

      def initialize
        @steps = []
      end

      def each(*types)
        types = types.flatten

        @steps.each do |step|
          if types.include?(step.class.to_sym)
            if step.class.to_sym == :group
              step.steps.each(*types) do |step|
                yield step
              end
            else
              yield step
            end
          elsif types.empty?
            yield step
          end
        end
      end

      def find(key)
        @steps.find { |step| step.has?(:key) && step.key == key.to_s }
      end

      def find!(key)
        find(key) || raise(ArgumentError, "Can't find step with key: #{key}")
      end

      def push(step)
        @steps.push(step)
      end

      def to_definition
        @steps.map(&:to_h)
      end
    end
  end
end
