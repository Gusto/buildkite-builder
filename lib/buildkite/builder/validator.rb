# frozen_string_literal: true

require 'json_schemer'
require 'pathname'

module Buildkite
  module Builder
    class Validator
      using Rainbow

      class ValidationError
        attr_reader :source_location

        def initialize(error = {}, source_location: nil)
          @error = error
          @source_location = source_location
        end

        def pointer
          @error['data_pointer'] || ''
        end

        def attribute
          segment = pointer.split('/').last
          segment && !segment.empty? ? segment : 'pipeline'
        end

        def formatted_message
          case @error['type']
          when 'string', 'integer', 'number', 'boolean', 'array', 'object', 'null'
            type = @error['type']
            article = type.match?(/\A[aeiou]/) ? 'an' : 'a'
            "must be #{article} #{type}"
          when 'enum'
            values = @error.dig('schema', 'enum').map(&:inspect).join(', ')
            "must be one of: #{values}"
          when 'required'
            missing = @error.dig('details', 'missing_keys') || @error.dig('schema', 'required')
            missing = missing.join(', ') if missing.is_a?(Array)
            "is missing required attributes: #{missing}"
          when 'additionalProperties', 'schema'
            "is not a recognized attribute"
          when 'minimum'
            "must be at least #{@error.dig('schema', 'minimum')}"
          when 'maximum'
            "must be at most #{@error.dig('schema', 'maximum')}"
          when 'pattern'
            "does not match expected format"
          when 'minItems'
            "must have at least #{@error.dig('schema', 'minItems')} item(s)"
          else
            @error['error']
          end
        end

        def to_s
          location = source_location ? "#{source_location.file}:#{source_location.line_number}".color(:dimgray) + ' ' : ''
          "#{location}#{attribute.bright}: #{formatted_message}"
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
          ValidationError.new(error)
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
        @default_schemer ||= suppress_warnings { JSONSchemer.schema(Pathname.new(default_schema_path.to_s)) }
      end

      # The Buildkite schema contains regex patterns with unescaped hyphens in
      # character classes (e.g. /^[a-zA-Z0-9-_]+$/), which trigger harmless
      # Ruby warnings when json_schemer compiles them.
      def self.suppress_warnings
        original = $VERBOSE
        $VERBOSE = nil
        yield
      ensure
        $VERBOSE = original
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
            ValidationError.new(error, source_location: step_obj.source_location)
          end
        end
      end
    end
  end
end
