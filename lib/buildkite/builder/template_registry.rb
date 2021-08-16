module Buildkite
  module Builder
    class TemplateRegistry
      def initialize(root)
        @templates = {}

        Loaders::Templates.load(root).each do |name, asset|
          @templates[name.to_s] = asset
        end
      end

      def find(name)
        return unless name

        unless definition = @templates[name.to_s]
          raise ArgumentError, "Template not defined: #{name}"
        end

        definition
      end

      def to_definition
        # No-op
      end
    end
  end
end
