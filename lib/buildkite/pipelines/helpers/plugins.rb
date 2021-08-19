# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Plugins
        def plugin(plugin_name, options = nil)
          plugin_name = plugin_name.to_s
          @plugins ||= {}

          if @plugins.key?(plugin_name)
            raise ArgumentError, "Plugin already used for command step: #{plugin_name}"
          end

          uri, version = step_collection.plugins.fetch(plugin_name)
          new_plugin = Plugin.new(uri, version, options)
          @plugins[plugin_name] = new_plugin

          plugins(new_plugin.to_h)
        end
      end
    end
  end
end
