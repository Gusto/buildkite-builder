module Buildkite
  module Builder
    class Data
      def initialize(source_hash = nil)
        @data = Hash.new

        if source_hash
          source_hash.transform_keys(&:to_sym)
          @data.merge!(source_hash)
        end
      end

      def []=(key, value)
        @data[key.to_sym] = value
      end

      def to_pipeline
      end

      private

      def method_missing(name, *args, &block)
        name = name.to_sym

        if respond_to_missing?(name)
          return @data[name]
        end

        @data.public_send(name, *args, &block)
      end

      def respond_to_missing?(symbol, *)
        @data.key?(symbol)
      end
    end
  end
end
