module Buildkite
  module Builder
    class PluginCollection
      attr_reader :plugin_manager

      def initialize(plugin_manager)
        @plugin_manager = plugin_manager
        @collection = []
      end

      def add(resource, options)
        plugin =
          case resource
          when Symbol
            Plugin.new(plugin_manager.fetch(resource.to_s), options)
          when String
            Plugin.new(resource, options)
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
          else raise ArgumentError, "Unknown source #{source.inpect}"
          end

        @collection.select do |plugin|
          plugin.source == source_string
        end
      end
    end
  end
end
