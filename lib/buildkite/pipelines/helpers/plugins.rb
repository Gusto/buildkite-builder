# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Plugins
        def plugin(name_or_source, plugin_attributes = {})
          append(:plugins, { name_or_source => plugin_attributes })
        end
      end
    end
  end
end
