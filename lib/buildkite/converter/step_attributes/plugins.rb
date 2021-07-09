module Buildkite
  module Converter
    module StepAttributes
      class Plugins < Abstract
        def parse
          plugins = value

          plugins.inject([]) do |output, plugin|
            raise 'Expecting only one plugin name' unless plugin.keys.size == 1

            output << parse_plugin(plugin)
          end.join("\n")
        end

        def parse_plugin(hash)
          plugin_source, plugin_config = hash.to_a.first

          plugin_reference = register_plugin(plugin_source)

          if plugin_config
            string_start = "plugin :#{plugin_reference}, {"
            string_end = "}"
            output = [string_start]

            parsed_config = PluginConfigParser.new(plugin_config, 1).parse

            output.concat(parsed_config)
            output.append(string_end)

            output.join("\n")
          else
            "plugin #{plugin_reference.to_sym}"
          end
        end

        def register_plugin(plugin_key)
          # This registers the plugin the PluginStore and gets the reference
          ::Buildkite::Converter::PluginsStore.parse_plugin(plugin_key)
        end
      end

      class PluginConfigParser
        attr_reader :config, :depth

        def initialize(config, depth = 0)
          @config = config
          @depth = depth
        end

        def padding(additional = 0)
          '  ' * (depth + additional)
        end

        def parse
          config.inject([]) do |output, (key, value)|
            case value.class.to_s.to_sym
            when :String
              output << "#{padding}#{key}: '#{value}',"
            when :FalseClass, :TrueClass
              output << "#{padding}#{key}: #{value},"
            when :Array
              string_start = "#{padding}#{key}: %w("
              string_end = "#{padding}),"
              sub_output = value.map do |line|
                "#{padding(1)}#{line}"
              end

              sub_output.prepend(string_start)
              sub_output.append(string_end)

              output << sub_output.join("\n")
            when :Hash
              string_start = "#{padding}#{key}: {"
              string_end = "#{padding}},"

              sub_output = PluginConfigParser.new(value, depth + 1).parse

              sub_output.prepend(string_start)
              sub_output.append(string_end)

              output << sub_output.join("\n")
            end
          end
        end
      end
    end
  end
end
