module Buildkite
  module Builder
    class Group
      attr_reader :label
      attr_reader :data

      def initialize(label, steps, &block)
        @label = label
        @data = Data.new(
          steps: StepCollection.new(
            steps.templates,
            steps.plugins
          )
        )

        dsl = Dsl.new(self)
        dsl.extend(Extensions::Steps)
        dsl.instance_eval(&block)
      end

      def to_h
        { group: label }.merge(data.to_definition)
      end
    end
  end
end
