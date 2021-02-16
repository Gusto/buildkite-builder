# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Preview < Abstract
        private

        self.description = 'Outputs the pipeline YAML.'

        def run
          pipeline = ARGV.last

          if !pipeline && !root_pipeline?
            if available_pipelines.one?
              pipeline = available_pipelines.first
            else
              raise 'You must specify a pipeline'
            end
          end

          puts Runner.new(pipeline: pipeline).run.to_yaml
        end

        def root_pipeline?
          pipelines_path.join(Context::PIPELINE_DEFINITION_FILE).exist?
        end
      end
    end
  end
end
