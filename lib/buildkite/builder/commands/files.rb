# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Files < Abstract
        private

        self.description = 'Outputs files that match the specified manifest.'

        def run
          pipeline, manifest = ARGV.first.to_s.split('/')
          if !pipeline || !manifest
            raise 'You must specify a pipeline and a manifest (eg "mypipeline/mymanifest")'
          end

          manifests = Loaders::Manifests.load(pipeline)
          manifests[manifest].files.each do |file|
            puts file
          end
        end
      end
    end
  end
end
