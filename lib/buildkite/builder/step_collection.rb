module Buildkite
  module Builder
    class StepCollection
      attr_reader :templates
      attr_reader :plugins
      attr_reader :steps

      def initialize(templates, plugins)
        @templates = templates
        @plugins = plugins
        @steps = []
      end

      def each(*types)
        types = types.flatten

        @steps.each do |step|
          if types.include?(step.class.to_sym)
            yield step
          end

          if step.is_a?(Group)
            step.data.steps.each(*types) do |step|
              yield step
            end
          end
        end
      end

      def add(step_class, template = nil, **args, &block)
        @steps.push(step_class.new(self, template, **args, &block)).last
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
