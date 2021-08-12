# frozen_string_literal: true

module Buildkite
  module Builder
    class Extension
      class << self
        attr_reader :dsl_module

        def dsl(&block)
          @dsl_module = Module.new(&block)
        end
      end

      attr_reader :context

      def initialize(context)
        @context = context
      end

      def build
        # Override to provide extra functionality.
      end
    end
  end
end
