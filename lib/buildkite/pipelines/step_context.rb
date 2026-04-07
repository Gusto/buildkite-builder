# frozen_string_literal: true

module Buildkite
  module Pipelines
    SourceLocation = Struct.new(:file, :line_number, keyword_init: true)

    class StepContext
      attr_reader :step
      attr_reader :args
      attr_reader :data
      attr_accessor :source_location

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
