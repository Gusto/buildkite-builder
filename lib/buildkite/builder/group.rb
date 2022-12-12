module Buildkite
  module Builder
    class Group
      include Buildkite::Pipelines::Attributes

      attr_reader :label
      attr_reader :data

      attribute :depends_on, append: true
      attribute :key

      def self.to_sym
        name.split('::').last.downcase.to_sym
      end

      def initialize(label, context, &block)
        @label = label
        @data = Data.new
        @data.steps = StepCollection.new
        @data.notify = []

        # Use `clone` to copy over dsl's extended extensions
        @dsl = context.dsl.clone
        # Override dsl context to current group
        @dsl.instance_variable_set(:@context, self)

        instance_eval(&block) if block_given?
        self
      end

      def to_h
        attributes = super
        { group: label }.merge(attributes).merge(data.to_definition)
      end

      def method_missing(method_name, *args, **kwargs, &_block)
        @dsl.public_send(method_name, *args, **kwargs, &_block)
      end
    end
  end
end
