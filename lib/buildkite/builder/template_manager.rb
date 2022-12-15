module Buildkite
  module Builder
    class TemplateManager
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
    end
  end
end
