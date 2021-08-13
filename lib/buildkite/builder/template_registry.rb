module Buildkite
  module Builder
    class TemplateRegistry
      def initialize
        # Load templates here...
      end

      def find(name)
        return unless name

        name = name.to_s
        definition
        raise ArgumentError, "Template not defined: #{template}"
      end
    end
  end
end
