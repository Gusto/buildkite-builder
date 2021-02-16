# frozen_string_literal: true

module Buildkite
  module Pipelines
    class StepContext
      attr_reader :step
      attr_reader :args

      def initialize(step, **args)
        @step = step
        @args = args
      end

      def pipeline
        step.pipeline
      end

      def [](key)
        args[key]
      end
    end
  end
end
