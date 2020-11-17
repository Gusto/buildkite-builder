# frozen_string_literal: true

module Buildkite
  module Builder
    module Loaders
      class Abstract
        attr_reader :assets
        attr_reader :pipeline

        def self.load(pipeline)
          new(pipeline).assets
        end

        def initialize(pipeline)
          @pipeline = pipeline
          @assets = {}
          load
        end

        private

        def buildkite_path
          Buildkite::Builder.root.join('.buildkite')
        end

        def pipeline_path
          buildkite_path.join("pipelines/#{pipeline}")
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
