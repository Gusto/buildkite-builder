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

          # Pass the relative pipeline path to the Pipeline instance
          # Let the Pipeline class handle its own metadata logic
          pipeline = Pipeline.new(pipeline_path, logger: log)
          
          if pipeline.already_uploaded?
            log.info "Pipeline #{relative_pipeline_path.to_s.yellow} already uploaded in #{Buildkite.env.step_id} step".color(:dimgray)
          else
            pipeline.upload
          end
        end
      end
    end
  end
end
