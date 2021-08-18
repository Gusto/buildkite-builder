module Buildkite
  module Builder
    class Group
      include Buildkite::Pipelines::Attributes

      attr_reader :label
      attr_reader :data

      attribute :depends_on, append: true
      attribute :key

      def initialize(label, steps, &block)
        @label = label
        @data = Data.new(
          steps: StepCollection.new(
            steps.templates,
            steps.plugins
          ),
          notify: []
        )

        @dsl = Dsl.new(self)
        @dsl.extend(Extensions::Steps)
        @dsl.extend(Extensions::Notify)
        instance_eval(&block)
      end

      def to_h
        attributes = super
        { group: label }.merge(attributes).merge(data.to_definition)
      end

      def method_missing(method_name, *_args, &_block)
        @dsl.public_send(method_name, *_args, &_block)
      end
    end
  end
end
