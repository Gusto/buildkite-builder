module Buildkite
  module Converter
    class PluginsStore
      PluginStruct = Struct.new(:raw_source, :source, :version, :reference)

      class << self
        def plugins
          @plugins ||= {}
        end

        def parse_plugin(string)
          plugin = register_plugin(string)
          plugin.reference
        end

        def register_plugin(string)
          return plugins[string] if plugins.include?(string)

          source, version = string.split('#')

          unless version
            puts "WARNING: a specific version has not been supplied for the plugin: '#{string}'."
            puts "WARNING: it's advised to tie your plugin to a specific version."
          end

          # Register plugin in the store
          plugin_number = plugins.count
          plugins[string] = PluginStruct.new(string, source, version, "plugin_#{plugin_number}")
        end

        def contents
          plugins.inject([]) do |output, (source_string, struct)|
            line = "plugin(:#{struct.reference}, '#{struct.source}', '#{struct.version}')"
            output << line

            output
          end
        end
      end
    end
  end
end