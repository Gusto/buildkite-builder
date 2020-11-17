# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Preview < Abstract
        private

        self.description = 'Outputs the pipeline YAML.'

        def run
          unless pipeline
            raise 'You must specify a pipeline'
          end

          puts Runner.new(pipeline: pipeline).run.to_yaml
        end

        def pipeline
          @pipeline ||= ARGV.last || begin
            if available_pipelines.one?
              available_pipelines.first
            end
          end
        end
      end
    end
  end
end
