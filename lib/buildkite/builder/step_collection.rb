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

      def add(step_class, template = nil, **args, &block)
        @steps.push(step_class.new(templates.find(template), **args, &block)).last
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
