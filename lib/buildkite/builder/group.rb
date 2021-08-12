module Buildkite
  module Builder
    class Group
      attr_reader :label
      attr_reader :data

      def initialize(label, &block)
        @label = label
        @data = Data

        dsl = Dsl.new(self, @data)
        dsl.extend(Extensions::Steps.dsl_module)
        dsl.instance_eval(&block)
      end

      def to_pipeline
        # TODO: translate group data
      end
    end
  end
end
