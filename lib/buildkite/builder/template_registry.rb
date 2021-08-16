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

      def find!(name)
        unless name
          raise ArgumentError, "Template name cannot be nil"
        end

        find(name)
      end

      def to_definition
        # No-op
      end
    end
  end
end
