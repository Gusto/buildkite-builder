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
          pipeline = Pipeline.new(pipeline_path)
          validator = options[:schema] ? Validator.new(schema_path: options[:schema]) : Validator.new
          errors = validator.validate_all(pipeline.to_h, pipeline.steps)

          if errors.empty?
            puts "#{'Pipeline is valid.'.color(:springgreen)}"
          else
            errors.each { |error| $stderr.puts error.to_s }
            if options[:strict]
              abort "Pipeline validation failed with #{errors.size.to_s.yellow} error(s)."
            else
              $stderr.puts "Pipeline validation produced #{errors.size.to_s.yellow} warning(s)."
              $stderr.puts "Pass --strict to fail on validation errors. This will become the default in the next major release.".color(:dimgray)
            end
          end
        end
      end
    end
  end
end
