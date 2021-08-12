module Buildkite
  module Builder
    class Group
      attr_reader :label
      attr_reader :data
      attr_reader :templates

      def initialize(label, templates, &block)
        @label = label
        @data = Data.new(steps: [])
        @templates = templates

        dsl = Dsl.new(self, @data)
        dsl.extend(Extensions::Steps.dsl_module)
        dsl.instance_eval(&block)
      end

      def to_pipeline
        { group: label, steps: data[:steps].map(&:to_pipeline) }
      end
    end
  end
end
