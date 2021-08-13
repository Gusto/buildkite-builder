module Buildkite
  module Builder
    class StepsCollection
      def initialize
      end

      def add(step)

      end

      def add(step_class, template = nil, **args, &block)
        steps.push(step_class.new(templates.find(template), **args, &block)).last
      end

      def to_definition
      end

      private

      def templates
        context.data[:templates]
      end
    end
  end
end
