module Buildkite
  module Converter
    class AttributeParser
      class << self
        def parse(attribute_name, attribute_value)
          case attribute_name
          when 'name', 'label'
            parse_label(attribute_value)
          when 'timeout_in_minutes'
            parse_timeout(attribute_value)
          when 'command'
            parse_command(attribute_value)
          when 'agents'
            parse_agents(attribute_value)
          when 'retry'
            parse_retry(attribute_value)
          when 'wait'
            'wait'
          when 'plugins'
            "Plugin detected: #{attribute_value}"
            # parse_plugins(attribute_value)
          else
            default_parse(attribute_name, attribute_value)
          end
        end
  
        def parse_plugins(value)
          raise ArgumentError, "Expecting an Array, got a '#{value.class}'" unless value.is_a?(Array)

          ouptut = []

          value.each do |plugin|
            raise 'Expecting only one plugin name' unless plugin.keys.size == 1

            plugin_identifier = plugin.keys.first
            plugin_configuration = plugin.values.first

            output << "plugin :#{plugin_identifier},"

            configuration_output = []
            plugin_configuration.each do |key, value|
              configuration_output_string = case value.class.to_s
                                            when 'String'
                                              "#{key}: '#{value}'"
                                            when 'Numeric'
                                            when 'Array'

                                            when 'Hash'
                                              raise 'Found Hash'
                                            end

              configuration_output << configuration_output_string
            end
          end

        end

        def default_parse(name, value)
          case value.class.to_s
          when 'String'
            "#{name} :#{value}"
          when 'Numeric'
            "#{name} #{value}"
          when 'Array'
            ""
          when 'Hash'
            ""
          else
            raise ArgumentError, "Unable to parse, was given unexpected type '#{value.class}' for attribute '#{name}'."
          end
        end

        def parse_retry(value)
          raise ArgumentError, "Expecting a Hash, got a '#{value.class}'" unless value.is_a?(Hash)

          output = []

          if value.include?('automatic')
            retry_conditions = value['automatic']

            retry_conditions.each do |hash|
              status = hash.fetch('exit_status')
              limit = hash.fetch('limit')
              output << "automatically_retry status: #{status}, limit: #{limit}"
            end
          end

          if value.include?('manual')
            raise 'Manual retry is not currently supported in the Buildkite Builder DSL.'
          end

          output
        end

        def parse_agents(value)
          raise ArgumentError, "Expecting a Hash, got a '#{value.class}'" unless value.is_a?(Hash)

          queue = value.fetch('queue')
          "agents queue: :#{queue}"
        end

        def parse_command(string)
          "command '#{string}'"
        end

        def parse_timeout(string)
          "timeout #{string}"
        end

        def parse_label(string)
          emoji = /:(\w*):\s?/

          matches = string.scan(emoji).flatten
          matches.map! { |str| ":#{str}" }
          stripped_string = string.gsub(emoji, '')

          "label '#{stripped_string}', emoji: [#{matches.join(', ')}]"
        end
      end
    end
  end
end

