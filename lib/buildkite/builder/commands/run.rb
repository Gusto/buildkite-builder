# frozen_string_literal: true

require 'tempfile'

module Buildkite
  module Builder
    module Commands
      class Run < Abstract
        private
        include LoggingUtils
        using Rainbow

        self.description = 'Builds and uploads the generated pipeline.'

        def run
          pipeline_name = pipeline_slug || pipeline_root_path

          # This entrypoint is for running on CI. It expects certain environment
          # variables to be set. It also uploads the pipeline to Buildkite.
          log.info "#{'+++ ' if Buildkite.env}🧰 " + 'Buildkite Builder'.color(:springgreen) + " ─ #{pipeline_name.to_s.yellow}"
          context = Context.new(pipeline_root_path, logger: log)
  
          results = benchmark("\nDone (%s)".color(:springgreen)) do
            context.build
          end
          log.info(results)
  
          upload(context.pipeline)
        end
  
        private
  
        def upload(pipeline)
          # Upload the pipeline.
          Tempfile.create(['pipeline', '.yml']) do |file|
            file.sync = true
            file.write(pipeline.to_yaml)
  
            log.info '+++ :paperclip: Uploading artifact'
            Buildkite::Pipelines::Command.artifact!(:upload, file.path)
            log.info '+++ :pipeline: Uploading pipeline'
            Buildkite::Pipelines::Command.pipeline!(:upload, file.path)
          end
        end
      end
    end
  end
end
