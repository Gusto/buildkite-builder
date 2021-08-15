# frozen_string_literal: true

module Buildkite
  module Builder
    class Dsl
      attr_reader :context

      def initialize(context)
        @context = context
      end
    end
  end
end
