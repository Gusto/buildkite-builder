module Buildkite
  module Builder
    class Group
      attr_reader :label
      attr_reader :data

      def initialize(label, pipeline, &block)
        @label = label

        @data = pipeline.data.dup
        @data[:steps] = StepsCollection.new(pipeline)

        dsl = Dsl.new(self)
        dsl.extend(Extensions::Steps.dsl_module)
        dsl.instance_eval(&block)
      end

      def to_h
        {
          group: label,
          steps: data[:steps].to_definition
        }
      end
    end
  end
end
