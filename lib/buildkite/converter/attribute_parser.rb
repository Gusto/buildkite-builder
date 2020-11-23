module Buildkite
  module Converter
    class AttributeParser
      class << self
        def parse(attribute_name, attribute_value)
          case attribute_name.to_sym
          when :name, :label
            StepAttributes::Label.parse('label', attribute_value)
          when :block
            StepAttributes::Label.parse(attribute_name, attribute_value)
          when :timeout_in_minutes
            # Attribute name is 'timeout_in_minutes' but is 'timeout' in Buildkite Builder DSL
            StepAttributes::Timeout.parse(nil, attribute_value)
          when :command, :prompt, :async, :trigger
            StepAttributes::SimpleString.parse(attribute_name, attribute_value)
          when :agents
            StepAttributes::Agents.parse(attribute_name, attribute_value)
          when :retry
            StepAttributes::Retry.parse(attribute_name, attribute_value)
          when :wait
            StepAttributes::Wait.parse(attribute_name, attribute_value)
          when :plugins
            StepAttributes::Plugins.parse(attribute_name, attribute_value)
          when :env
            StepAttributes::Env.parse(attribute_name, attribute_value)
          when :parallelism
            StepAttributes::Numeric.parse(attribute_name, attribute_value)
          when :build
            StepAttributes::Build.parse(attribute_name, attribute_value)
          when :if
            StepAttributes::Condition.parse(nil, attribute_value)
          else
            fallback_parsing(attribute_name, attribute_value)
          end
        end

        def fallback_parsing(attribute_name, attribute_value)
          case attribute_value.class.to_s.to_sym
          when :String
            StepAttributes::StringValue.parse(attribute_name, attribute_value)
          when :Array
            StepAttributes::ArrayType.parse(attribute_name, attribute_value)
          when :TrueClass, :FalseClass
            StepAttributes::Boolean.parse(attribute_name, attribute_value)
          else
            raise ArgumentError, "Unable to parse '#{attribute_name}'\nattribute_name: #{attribute_name}"
          end
        end
      end
    end
  end
end

