# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Plugins
        def plugin(name_or_source, options = nil)
          append(:plugins, plugin_collection.add(name_or_source, options).to_h)
        end

        def plugins
          plugin_collection
        end

        private

        def plugin_collection
          @plugin_collection ||= Buildkite::Builder::PluginCollection.new(step_collection.plugins)
        end
      end
    end
  end
end
