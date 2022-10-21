module Buildkite
  module Builder
    class PluginCollection
      attr_reader :plugin_manager

      def initialize(plugin_manager)
        @plugin_manager = plugin_manager
        @collection = []
      end

      def add(resource, attributes = {})
        plugin =
          case resource
          when Symbol
            registered_plugin = plugin_manager.fetch(resource.to_s)

            raise ArgumentError, "Plugin `#{resource}` does not exist" unless registered_plugin

            Plugin.new(registered_plugin[:uri], registered_plugin[:default_attributes].merge(attributes))
          when String
            Plugin.new(resource, attributes)
          when Plugin
            resource
          else
            raise ArgumentError, "Unknown plugin `#{resource.inspect}`"
          end

        @collection.push(plugin).last
      end

      def find(source)
        source_string =
          case source
          when String then source
          when Plugin then source.source
          else raise ArgumentError, "Unknown source #{source.inspect}"
          end

        @collection.select do |plugin|
          plugin.source == source_string
        end
      end

      def to_definition
        @collection.map(&:to_h)
      end
    end
  end
end
