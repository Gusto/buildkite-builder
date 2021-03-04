# frozen_string_literal: true

module Buildkite
  module Builder
    module Commands
      class Files < Abstract
        private

        self.description = 'Outputs files that match the specified manifest.'

        def run
          manifests = Loaders::Manifests.load(pipeline_path)
          puts manifests[options[:manifest]].files.sort.join("\n")
        end

        def parse_options(opts)
          opts.on('--manifest MANIFEST', 'The manifest to use') do |manifest|
            options[:manifest] = manifest
          end
        end
      end
    end
  end
end
