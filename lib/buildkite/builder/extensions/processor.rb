module Buildkite
  module Builder
    module Extensions
      class Processor < Extension
        def build(**args)
          _log_run { run(**args) }
        end

        private

        def run
          raise NotImplementedError
        end

        def log
          context.logger
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
          steps = datap[:steps]
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
