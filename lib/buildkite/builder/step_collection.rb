module Buildkite
  module Builder
    class StepCollection
      attr_reader :context

      def initialize(context)
        @context = context
        @steps = []
      end

      def add(step_class, template = nil, **args, &block)
        @steps.push(step_class.new(templates.find(template), **args, &block)).last
      end

      def push(step)
        @steps.push(step)
      end

      def to_definition
        @steps.map(&:to_h)
      end

      private

      def templates
        context.data[:templates]
      end
    end
  end
end
