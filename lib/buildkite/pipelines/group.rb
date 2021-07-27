module Buildkite
  module Pipelines
    class Group < Builder
      attr_reader :name

      def initialize(name, &block)
        @name = name

        super(nil, &block)
      end

      def to_h
        Helpers.sanitize(group: name, steps: steps.map(&:to_h))
      end
    end
  end
end
