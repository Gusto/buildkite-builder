# frozen_string_literal: true

module Buildkite
  module Builder
    class Dsl
      attr_reader :context

      def extend(mod)
        if mod < Extension
          super(mod.dsl) if mod.dsl
        else
          super
        end
      end

      def initialize(context)
        @context = context
      end
    end
  end
end
