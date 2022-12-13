module Buildkite
  module Builder
    class Group
      include Buildkite::Pipelines::Attributes

      attr_reader \
        :label,
        :data,
        :extensions,
        :root,
        :dsl

      attribute :depends_on, append: true
      attribute :key

      def self.to_sym
        name.split('::').last.downcase.to_sym
      end

      def initialize(label, context, &block)
        @label = label
        @root = context.root
        @data = Data.new
        @extensions = ExtensionManager.new(self)
        @dsl = Dsl.new(self)

        extensions.use(Extensions::Notify)
        extensions.use(Extensions::Steps)

        instance_eval(&block) if block_given?
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
