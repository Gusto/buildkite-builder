# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Validate < Abstract
        using Rainbow

        self.description = 'Validates the pipeline against the Buildkite schema.'

        private

        def parse_options(opts)
          super
          opts.on('--schema PATH', 'Path to a custom JSON schema file') do |path|
            options[:schema] = path
          end
        end

        def run
          enforce_strict_default_migration!

          pipeline = Pipeline.new(pipeline_path)
          validator = options[:schema] ? Validator.new(schema_path: options[:schema]) : Validator.new
          errors = validator.validate_all(pipeline.to_h, pipeline.steps)

          log_validation_results(errors)
        end
      end
    end
  end
end
