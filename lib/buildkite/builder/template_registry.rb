module Buildkite
  module Builder
    class TemplateRegistry
      attr_reader :context

      def initialize(context)
        @templates = {}

        Loaders::Templates.load(context.root).each do |name, asset|
          @templates[name.to_s] = asset
        end
      end

      def find(name)
        return unless name

        definition = @templates[name.to_s]

        raise ArgumentError, "Template not defined: #{name}" unless definition

        definition
      end

      def to_definition
        # No-op
      end
    end
  end
end
