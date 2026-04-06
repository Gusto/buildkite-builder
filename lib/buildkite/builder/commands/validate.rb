# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Validate < Abstract
        self.description = 'Validates the pipeline against the Buildkite schema.'

        private

        def parse_options(opts)
          opts.on('--schema PATH', 'Path to a custom JSON schema file') do |path|
            options[:schema] = path
          end
        end

        def run
          pipeline = Pipeline.new(pipeline_path)
          validator = options[:schema] ? Validator.new(schema_path: options[:schema]) : Validator.new
          errors = validator.validate_all(pipeline.to_h, pipeline.steps)

          if errors.empty?
            puts 'Pipeline is valid.'
          else
            errors.each do |error|
              location = error.source_location ? "#{error.source_location.file}:#{error.source_location.line_number} " : ''
              $stderr.puts "#{location}#{error.pointer}: #{error.message}"
            end
            abort "Pipeline validation failed with #{errors.size} error(s)."
          end
        end
      end
    end
  end
end
