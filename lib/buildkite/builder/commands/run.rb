# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Run < Abstract
        private

        self.description = 'Builds and uploads the generated pipeline.'

        def run
          unless pipeline
            raise 'You must specify a pipeline'
          end

          Builder::Runner.run
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
