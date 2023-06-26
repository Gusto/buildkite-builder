# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Run < Abstract
        private
        include LoggingUtils
        using Rainbow

        self.description = 'Builds and uploads the generated pipeline.'

        def run
          relative_pipeline_path = pipeline_path.relative_path_from(Builder.root)

          # This entrypoint is for running on CI. It expects certain environment
          # variables to be set. It also uploads the pipeline to Buildkite.
          log.info "+++ 🧰 #{'Buildkite Builder'.color(:springgreen)} v#{Buildkite::Builder.version} ─ #{relative_pipeline_path.to_s.yellow}"

          if Buildkite::Pipelines::Command.meta_data(:get, Builder.meta_data.fetch(:job)) == Buildkite.env.step_id
            log.info "Pipeline already uploaded in #{Buildkite.env.step_id} step".color(:dimgray)
          else
            Pipeline.new(pipeline_path, logger: log).upload
          end
        end

        private

        def pipeline_path
          pipeline_path_override || super
        end

        def pipeline_path_override
          if ENV['BUILDKITE_BUILDER_PIPELINE_PATH']
            path = Pathname.new(ENV['BUILDKITE_BUILDER_PIPELINE_PATH'])
            path.absolute? ? path : Builder.root.join(path)
          end
        end
      end
    end
  end
end
