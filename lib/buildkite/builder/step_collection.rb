module Buildkite
  module Builder
    class StepCollection
      STEP_TYPES = {
        block: Pipelines::Steps::Block,
        command: Pipelines::Steps::Command,
        group: Pipelines::Steps::Group,
        input: Pipelines::Steps::Input,
        trigger: Pipelines::Steps::Trigger,
        wait: Pipelines::Steps::Wait
      }.freeze

      attr_reader :steps

      def initialize
        @steps = []
      end

      def each(*types, traverse_groups: true, &block)
        types = types.flatten
        types.map! { |type| STEP_TYPES.values.include?(type) ? type : STEP_TYPES.fetch(type) }
        types = STEP_TYPES.values if types.empty?

        matched_steps = steps.each_with_object([]) do |step, matches|
          if types.any? { |step_type| step.is_a?(step_type) }
            matches << step
          end
          if step.is_a?(Pipelines::Steps::Group) && traverse_groups
            step.steps.each(types) { |step| matches << step }
          end
        end
        matched_steps.each(&block)
      end

      def find(key)
        steps.find { |step| step.has?(:key) && step.key.to_s == key.to_s }
      end

      def remove(step)
        steps.delete(step)
      end

      def replace(old_step, new_step)
        steps[steps.index(old_step)] = new_step
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

      def empty?
        @steps.empty? || (@steps.all? { |step| step.is_a?(Pipelines::Steps::Group) && step.steps.empty? })
      end
    end
  end
end
