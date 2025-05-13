module Buildkite
  module Builder
    module Extensions
      class Plugins < Extension
        attr_reader :manager

        dsl do
          def plugin(name, uri, default_attributes = {})
            context.extensions.find(Buildkite::Builder::Extensions::Plugins).manager.add(name, uri, default_attributes)
          end

          def plugins(plugins)
            plugins.each do |plugin|
              name, uri, default_attributes = plugin
              context.extensions.find(Buildkite::Builder::Extensions::Plugins).manager.add(name, uri, default_attributes || {})
            end
          end
        end

        def prepare
          @manager = PluginManager.new
        end

        def build
          context.data.steps.each(:command) do |step|
            next unless step.has?(:plugins)

            step.get(:plugins).map! do |plugin|
              resource, attributes = extract_resource_and_attributes(plugin)
              resource.is_a?(Symbol) ? manager.build(resource, attributes) : plugin
            end
          end
        end

        private

        def extract_resource_and_attributes(plugin)
          [plugin.keys.first, plugin.values.first]
        end
      end
    end
  end
end
