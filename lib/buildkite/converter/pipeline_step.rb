module Buildkite
  module Converter
    class PipelineStep
      STEP_TYPES = {
          'command' => :Command,
          'wait' => :Wait,
          'block' => :Block,
          'input' => :Input,
          'trigger' => :Trigger
      }.freeze

      VALID_INPUT_TYPES = [String, Hash].freeze

      attr_reader :step

      def initialize(step)
        @step = step

        validate_step_type

        convert_string_step if step.is_a?(String)
      end


      def parse
        validate_step_type
        # type = get_step_type
        replace_key_name_to_label

        output = []

        step.each do |key, value|

        end
      end

      def get_step_type
        step_types = STEP_TYPES.select do |step_name, _|
          step.include?(step_name)
        end.values

        unless step_types.count == 1
          raise ArgumentError, "Unable to get step type, found #{step_types.count} possible step types: #{step_types.join(', ')}"
        end

        step_types.first
      end

      def convert_string_step
        @step = { "#{step}" => nil }
      end

      def replace_key_name_to_label
        # the 'name' and 'label' key are aliases, with 'label' being preferred
        # https://github.com/buildkite/docs/issues/60

        if step.include?('name')
          @step = step.transform_keys { |key| key == 'name' ? 'label' : key }
        end
      end

      def validate_step_type
        unless VALID_INPUT_TYPES.include?(step.class)
          raise ArgumentError, "Unexpected type of '#{step.class}', valid types are #{VALID_INPUT_TYPES.join(',')}"
        end
      end
    end
  end
end