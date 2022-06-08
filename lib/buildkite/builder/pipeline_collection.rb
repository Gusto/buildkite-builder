require "forwardable"

module Buildkite
  module Builder
    class PipelineCollection
      extend Forwardable

      attr_reader :pipelines

      def_delegator :@pipelines, :count

      def initialize(artifacts)
        @artifacts = artifacts
        @pipelines = []
      end

      def add(pipeline)
        unless pipeline.is_a?(Buildkite::Builder::Extensions::SubPipelines::Pipeline)
          raise "`#{pipeline}` must be a Buildkite::Builder::Extensions::SubPipelines::Pipeline"
        end

        pipelines << pipeline
      end

      def to_definition
        # Instead of generates pipeline.yml, subpipelines save generated file to artifacts
        pipelines.each do |pipeline|
          file = Pathname.new(pipeline.pipeline_yml)
          file.dirname.mkpath
          file.write(YAML.dump(Pipelines::Helpers.sanitize(pipeline.to_h)))

          @artifacts << file
        end

        nil
      end
    end
  end
end
