# frozen_string_literal: true

module Buildkite
  module Builder
    class Extension
      class << self
        def dsl(&block)
          @dsl = Module.new(&block) if block_given?
          @dsl
        end
      end

      attr_reader :context
      attr_reader :options
      attr_reader :options_block

      def initialize(context, **options, &block)
        @context = context
        @options = options
        @options_block = block

        prepare
      end

      def build
        # Override to provide extra functionality.
      end

      private

      def log
        context.logger
      end

      def prepare
        # Override to provide extra functionality.
      end

      def pipeline(&block)
        context.dsl.instance_eval(&block)
      end
    end
  end
end
