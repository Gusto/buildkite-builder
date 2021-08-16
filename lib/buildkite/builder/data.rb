module Buildkite
  module Builder
    class Data
      def initialize
        @data = Hash.new
      end

      def method_missing(name, *args, &block)
        name = name.to_sym

        if respond_to_missing?(name)
          return @data[name]
        end

        super
      end

      def respond_to_missing?(symbol, *)
        @data.key?(symbol)
      end

      def to_pipeline
      end
    end
  end
end
