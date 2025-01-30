# frozen_string_literal: true

module Buildkite
  module Pipelines
    class StepContext
      attr_reader :step
      attr_reader :args
      attr_reader :data

      def initialize(step, **args)
        @step = step
        @args = args
        @data = {}
      end

      def [](key)
        args[key]
      end
    end
  end
end
