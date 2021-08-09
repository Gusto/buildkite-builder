# frozen_string_literal: true

module Buildkite
  module Builder
    module Processors
      class Abstract
        include LoggingUtils
        using Rainbow

        def initialize(pipeline)
          @pipeline = pipeline
        end

        def run
          _log_run { process }
        end

        private

        attr_reader :pipeline

        def process
          raise NotImplementedError
        end

        def log
          pipeline.logger
        end

        def buildkite
          @buildkite ||= begin
            unless Buildkite.env
              raise 'Must be in Buildkite environment to access the Buildkite API'
            end

            Buildkite::Pipelines::Api.new(Buildkite.env.api_token)
          end
        end

        def pipeline_steps(*types)
          steps = pipeline.steps
          types = types.flatten
          steps = steps.select { |step| types.include?(step.class.to_sym) } if types.any?
          steps
        end

        def _log_run
          log.info "\nProcessing ".color(:dimgray) + self.class.name.color(:springgreen)

          results = benchmark('└──'.color(:springgreen) + ' Finished in %s'.color(:dimgray)) do
            formatter = log.formatter
            log.formatter = proc do |_severity, _datetime, _progname, msg|
              '│'.color(:springgreen) + " #{msg}\n"
            end

            begin
              yield
            ensure
              log.formatter = formatter
            end
          end

          log.info results
        end
      end
    end
  end
end
