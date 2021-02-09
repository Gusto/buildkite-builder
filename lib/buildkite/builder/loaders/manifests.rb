# frozen_string_literal: true

module Buildkite
  module Builder
    module Loaders
      class Manifests < Abstract
        MANIFESTS_PATH = Pathname.new('manifests').freeze

        def load
          return unless manifests_path.directory?

          manifests_path.children.map do |file|
            add(file.basename, Manifest.new(Buildkite::Builder.root, file.readlines))
          end
        end

        def manifests_path
          root.join(MANIFESTS_PATH)
        end
      end
    end
  end
end
