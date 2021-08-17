# frozen_string_literal: true

module Buildkite
  module Builder
    class Extension
      class << self
        attr_reader :dsl

        def dsl(&block)
          @dsl = Module.new(&block) if block_given?
          @dsl
        end
      end

      attr_reader :context
      attr_reader :options

      def initialize(context, **options)
        @context = context
        @options = options

        prepare
      end

      def _build
        build(**options)
      end

      def build
        # Override to provide extra functionality.
      end

      private

      def buildkite
        @buildkite ||= begin
          unless Buildkite.env
            raise 'Must be in Buildkite environment to access the Buildkite API'
          end

          Buildkite::Pipelines::Api.new(Buildkite.env.api_token)
        end
      end

      def prepare
        # Override to provide extra functionality.
      end

      def pipeline(&block)
        context.dsl.instance_eval(&block) if block_given?
        context
      end
    end
  end
end
