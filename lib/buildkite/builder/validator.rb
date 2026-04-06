# frozen_string_literal: true

require 'json_schemer'
require 'pathname'

module Buildkite
  module Builder
    class Validator
      ValidationError = Struct.new(:pointer, :message, :source_location, keyword_init: true)

      STEP_SCHEMA_MAP = {
        'Buildkite::Pipelines::Steps::Command' => 'commandStep',
        'Buildkite::Pipelines::Steps::Block' => 'blockStep',
        'Buildkite::Pipelines::Steps::Input' => 'inputStep',
        'Buildkite::Pipelines::Steps::Trigger' => 'triggerStep',
        'Buildkite::Pipelines::Steps::Wait' => 'waitStep',
        'Buildkite::Pipelines::Steps::Group' => 'groupStep',
      }.freeze

      def initialize(schema_path: nil)
        path = schema_path || self.class.default_schema_path
        @schemer = JSONSchemer.schema(Pathname.new(path.to_s))
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

      # Validates both the full pipeline and each step against its type-specific
      # sub-schema. Step errors include source locations for precise error reporting.
      def validate_all(pipeline_hash, step_collection = nil)
        errors = validate(pipeline_hash)
        if step_collection
          step_hashes = pipeline_hash['steps'] || []
          errors += validate_steps(step_hashes, step_collection.steps)
        end
        errors
      end

      def self.default_schema_path
        File.expand_path('schema.json', __dir__)
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
          definition_name = STEP_SCHEMA_MAP[step_obj.class.name]
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
