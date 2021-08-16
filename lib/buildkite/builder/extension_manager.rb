module Buildkite
  module Builder
    class ExtensionManager
      def initialize(context)
        @context = context
        @extensions = {}
      end

      def use(extension, **args)
        unless extension < Buildkite::Builder::Extension
          raise "#{extension} must subclass Buildkite::Builder::Extension"
        end

        @extensions.push(extension.new(self, **args))
        context.dsl.extend(extension)
      end

      def build
        @extensions.each(&:_build)
      end
    end
  end
end
