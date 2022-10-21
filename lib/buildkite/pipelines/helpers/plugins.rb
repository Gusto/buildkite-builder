# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Plugins
        def plugin(name_or_source, plugin_attributes = {})
          attributes['plugins'] ||= Buildkite::Builder::PluginCollection.new(step_collection.plugins)
          attributes['plugins'].add(name_or_source, plugin_attributes)
        end

        def plugins
          attributes['plugins']
        end
      end
    end
  end
end
