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
