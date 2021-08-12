module Buildkite
  module Builder
    class Data < Hash
      def initialize(source_hash = nil)
        deep_update(source_hash) if source_hash

        super
      end

      alias regular_reader []
      alias regular_writer []=

      def custom_reader(key)
        regular_reader(convert_key(key))
      end

      def custom_writer(key, value, convert = true)
        v = convert ? convert_value(value) : value
        regular_writer(convert_key(key), v)
      end

      alias [] custom_reader
      alias []= custom_writer

      def deep_update(hash)
        _deep_update(hash)
        self
      end

      def to_pipeline
        each_with_object({}) do |(k, v), hash|
          value = if v.is_a?(Array)
            v.map do |item|
              item.respond_to?(:to_pipeline) ? item.to_pipeline : item
            end
          else
            v.respond_to?(:to_pipeline) ? v.to_pipeline : v
          end

          hash[k] = value
        end
      end

      private

      def _deep_update(hash)
        hash.each do |k, v|
          key = convert_key(k)

          if v.is_a?(Hash) && key?(key) && regular_reader(key).is_a?(Data)
            custom_reader(key).deep_update(v)
          else
            regular_writer(key, convert_value(v))
          end
        end
      end

      def convert_key(key)
        key.to_s
      end

      def convert_value(val) #:nodoc:
        case val
        when self.class
          val.dup
        when ::Hash
          self.class.new(val)
        when Array
          Array.new(val.map { |e| convert_value(e) })
        else
          val
        end
      end
    end
  end
end
