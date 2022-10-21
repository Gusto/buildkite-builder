module Buildkite
  module Builder
    class PluginManager
      def initialize
        @plugins = {}
      end

      def add(name, uri, default_attributes = {})
        name = name.to_s

        if @plugins.key?(name)
          raise ArgumentError, "Plugin already defined: #{name}"
        end

        @plugins[name] = {
          uri: uri,
          default_attributes: default_attributes
        }
      end

      def fetch(name)
        @plugins[name]
      end

      def to_definition
        # No-op
      end
    end
  end
end
