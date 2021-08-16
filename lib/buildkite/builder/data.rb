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

      def to_definition
        @data.each_with_object({}) do |(key, value), hash|
          value = value.respond_to?(:to_definition) ? value.to_definition : value

          next unless value

          hash[key] = value
        end
      end

      private

      def method_missing(name, *args, &block)
        if name.end_with?('=')
          name = name.to_s.delete_suffix('=').to_sym

          if respond_to_missing?(name)
            raise ArgumentError, "Data already contains key '#{name}'"
          else
            return @data[name] = args.first
          end
        elsif respond_to_missing?(name)
          return @data[name]
        end

        super
      end

      def respond_to_missing?(name, *)
        @data.key?(name)
      end
    end
  end
end
