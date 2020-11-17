# frozen_string_literal: true

require 'benchmark'

module Buildkite
  module Builder
    module LoggingUtils
      def benchmark(output, &block)
        time = Benchmark.realtime(&block)
        output % [pluralize(time.round(2), 'second')]
      end

      def pluralize(count, singular, plural = nil)
        if count == 1
          "#{count} #{singular}"
        elsif plural
          "#{count} #{plural}"
        else
          "#{count} #{singular}s"
        end
      end
    end
  end
end
