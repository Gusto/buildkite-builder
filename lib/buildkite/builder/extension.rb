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
      attr_reader :options

      def initialize(context, **options)
        @context = context
        @options = options

        prepare
      end

      def build
        # Override to provide extra functionality.
      end

      private

      def prepare
        # Override to provide extra functionality.
      end
    end
  end
end
