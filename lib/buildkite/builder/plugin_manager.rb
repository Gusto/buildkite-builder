module Buildkite
  module Builder
    class PluginManager
      def initialize
        @plugins = {}
      end

      def add(name, uri, default_attributes = {})
        name = name.to_s
        raise(ArgumentError, "Plugin already defined: #{name}") if @plugins.key?(name)

        @plugins[name] = Plugin.new(uri, default_attributes)
      end

      def build(name, attributes = {})
        plugin = @plugins[name.to_s]
        raise(ArgumentError, "Plugin is not registered: #{resource}") unless plugin

        { plugin.uri => plugin.default_attributes.merge(attributes) }
      end
    end
  end
end
