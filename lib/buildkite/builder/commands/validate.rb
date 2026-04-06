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
          validator = Validator.new(**validator_options)
          errors = validator.validate(pipeline.to_h)

          if errors.empty?
            puts 'Pipeline is valid.'
          else
            errors.each { |e| $stderr.puts "#{e.pointer}: #{e.message}" }
            abort "Pipeline validation failed with #{errors.size} error(s)."
          end
        end

        def validator_options
          options[:schema] ? { schema_path: options[:schema] } : {}
        end
      end
    end
  end
end
