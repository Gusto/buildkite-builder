# frozen_string_literal: true

require 'rspec/expectations'

module Buildkite
  module Builder
    module Matchers
      extend RSpec::Matchers::DSL

      # RSpec matcher that validates a pipeline hash against the Buildkite schema.
      #
      # Usage:
      #   expect(pipeline.to_h).to be_valid_pipeline
      #   expect(pipeline.to_h).to be_valid_pipeline.with_schema('/path/to/schema.json')
      matcher :be_valid_pipeline do
        chain :with_schema do |path|
          @schema_path = path
        end

        match do |pipeline_hash|
          validator_options = @schema_path ? { schema_path: @schema_path } : {}
          @errors = Validator.new(**validator_options).validate(pipeline_hash)
          @errors.empty?
        end

        failure_message do |_pipeline_hash|
          lines = @errors.map do |e|
            location = e.source_location ? " (#{e.source_location.file}:#{e.source_location.line_number})" : ''
            "  #{e.pointer}: #{e.message}#{location}"
          end
          "expected pipeline to be valid, but got #{@errors.size} error(s):\n#{lines.join("\n")}"
        end
      end
    end
  end
end
