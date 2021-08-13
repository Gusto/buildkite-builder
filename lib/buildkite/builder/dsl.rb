# frozen_string_literal: true

module Buildkite
  module Builder
    class Dsl
      attr_reader :context

      def initialize(context, extensions: false)
        @context = context
        @_supports_extensions = extensions
      end

      def use(extension_class, **args)
        unless @_supports_extensions
          raise "Context (#{_context}) does not support extensions"
        end

        context.register(extension_class, **args)
      end
    end
  end
end
