module Buildkite
  module Builder
    class StepCollection
      attr_reader :steps

      def initialize
        @steps = []
      end

      def each(*types)
        types = types.flatten

        yield_steps = []

        if types.empty?
          # Returns all
          yield_steps = @steps
          @steps.each do |step|
            if step.class.to_sym == :group
              step.steps.each { |step_in_group| yield_steps << step_in_group }
            end
          end
        else
          if types.include?(:group)
            yield_steps.concat(@steps.select { |step| step.class.to_sym == :group })
            types.delete(:group)
          end

          if types.any?
            @steps.each do |step|
              if types.include?(step.class.to_sym)
                yield_steps << step
              elsif step.class.to_sym == :group
                step.steps.each(*types) do |step|
                  yield_steps << step
                end
              end
            end
          end
        end

        yield_steps.each { |step| yield step }
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
