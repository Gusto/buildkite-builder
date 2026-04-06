# frozen_string_literal: true

require 'json_schemer'
require 'pathname'

module Buildkite
  module Builder
    class Validator
      ValidationError = Struct.new(:pointer, :message, :source_location, keyword_init: true) do
        def attribute
          pointer.split('/').last
        end

        def formatted_message
          normalize_message(message, attribute)
        end

        def to_s
          location = source_location ? "#{source_location.file}:#{source_location.line_number}  " : ''
          "#{location}'#{attribute}': #{formatted_message}"
        end

        private

        # Translate json_schemer's raw error into DSL-friendly language.
        def normalize_message(msg, attr)
          case msg
          when /is not an? (\w+)$/
            article = %w[array integer object].include?($1) ? 'an' : 'a'
            "must be #{article} #{$1}"
          when /is not one of: (.+)$/
            "must be one of #{$1}"
          when /is a disallowed additional property$/
            "is not a recognized attribute"
          when /is missing required properties: (.+)$/
            "is missing required attributes: #{$1}"
          else
            msg.sub(/\A(value|object|object property) at `\/[^`]*` /, '')
          end
        end
      end

      STEP_SCHEMA_MAP = {
        Pipelines::Steps::Command => 'commandStep',
        Pipelines::Steps::Block   => 'blockStep',
        Pipelines::Steps::Input   => 'inputStep',
        Pipelines::Steps::Trigger => 'triggerStep',
        Pipelines::Steps::Wait    => 'waitStep',
        Pipelines::Steps::Group   => 'groupStep',
      }.freeze

      def initialize(schema_path: nil)
        @schemer = if schema_path
          JSONSchemer.schema(Pathname.new(schema_path.to_s))
        else
          self.class.default_schemer
        end
      end

      def validate(pipeline_hash)
        @schemer.validate(pipeline_hash).map do |error|
          ValidationError.new(
            pointer: error['data_pointer'],
            message: error['error']
          )
        end
      end

      def valid?(pipeline_hash)
        @schemer.valid?(pipeline_hash)
      end

      def validate_all(pipeline_hash, step_collection = nil)
        if step_collection
          # Suppress per-step errors from the top-level pass; per-step validation
          # below catches the same violations with source location context.
          pipeline_errors = validate(pipeline_hash).reject { |e| e.pointer.start_with?('/steps/') }
          step_hashes = pipeline_hash['steps'] || []
          pipeline_errors + validate_steps(step_hashes, step_collection.steps)
        else
          validate(pipeline_hash)
        end
      end

      def self.default_schema_path
        File.expand_path('schema.json', __dir__)
      end

      def self.default_schemer
        @default_schemer ||= JSONSchemer.schema(Pathname.new(default_schema_path.to_s))
      end

      private

      def validate_steps(step_hashes, step_objects)
        errors = []
        step_hashes.each_with_index do |step_hash, index|
          step_obj = step_objects[index]
          next unless step_obj

          errors.concat(validate_step(step_hash, step_obj))
        end
        errors
      end

      def validate_step(step_hash, step_obj)
        if step_obj.is_a?(Pipelines::Steps::Group)
          nested_hashes = step_hash['steps'] || []
          nested_objects = step_obj.steps.steps
          validate_steps(nested_hashes, nested_objects)
        else
          definition_name = STEP_SCHEMA_MAP[step_obj.class]
          return [] unless definition_name

          step_schemer = @schemer.ref("#/definitions/#{definition_name}")
          return [] unless step_schemer

          step_schemer.validate(step_hash).map do |error|
            ValidationError.new(
              pointer: error['data_pointer'],
              message: error['error'],
              source_location: step_obj.source_location
            )
          end
        end
      end
    end
  end
end
