# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Preview < Abstract
        private

        self.description = 'Outputs the pipeline YAML.'

        def run
          puts Pipeline.new(pipeline_path).to_yaml
        end
      end
    end
  end
end
