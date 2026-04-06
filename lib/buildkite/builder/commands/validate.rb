# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Validate < Abstract
        self.description = 'Validates the pipeline against the Buildkite schema.'

        private

        def parse_options(opts)
          super
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
            errors.each { |error| $stderr.puts error.to_s }
            if options[:warn]
              $stderr.puts "Pipeline validation produced #{errors.size} warning(s)."
            else
              abort "Pipeline validation failed with #{errors.size} error(s)."
            end
          end
        end
      end
    end
  end
end
