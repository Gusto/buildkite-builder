# frozen_string_literal: true

module Buildkite
  module Builder
    class Dsl
      attr_reader :context

      def self.extend(mod)
        mod.is_a?(Extension) ? super(mod.dsl) : super
      end

      def initialize(context)
        @context = context
      end
    end
  end
end
