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

      def to_definition
        @data.each_with_object({}) do |(key, value), hash|
          value = value.respond_to?(:to_definition) ? value.to_definition : value

          next unless value

          hash[key] = value
        end
      end

      private

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
    end
  end
end
