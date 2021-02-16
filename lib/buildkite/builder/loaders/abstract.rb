# frozen_string_literal: true

module Buildkite
  module Builder
    module Loaders
      class Abstract
        attr_reader :assets
        attr_reader :root

        def self.load(root)
          new(root).assets
        end

        def initialize(root)
          @root = root
          @assets = {}
          load
        end

        private

        def buildkite_path
          Builder.root.join(Builder::BUILDKITE_DIRECTORY_NAME)
        end

        def load
          raise NotImplementedError
        end

        def add(name, asset)
          @assets[name.to_s] = asset
        end
      end
    end
  end
end
