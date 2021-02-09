# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Run < Abstract
        private

        self.description = 'Builds and uploads the generated pipeline.'

        def run
          # This entrypoint is for running on CI. It expects certain environment
          # variables to be set.
          options = {
            upload: true
          }

          if available_pipelines.include?(Buildkite.env.pipeline_slug)
            options[:pipeline] = Buildkite.env.pipeline_slug
          end

          Builder::Runner.new(**options).run
        end
      end
    end
  end
end
