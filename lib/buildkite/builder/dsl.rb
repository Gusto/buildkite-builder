# frozen_string_literal: true

module Buildkite
  module Builder
    class Dsl
      attr_reader :context
      attr_reader :data

      def initialize(context, data, extensions: false)
        @context = context
        @data = data
        @_supports_extentions = extensions
      end

      def use(extension_class, **args)
        unless @_supports_extentions
          raise "Context (#{_context}) does not support extensions"
        end

        _context.register(extension_class, **args)
      end
    end
  end
end
