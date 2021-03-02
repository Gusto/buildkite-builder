require 'logger'

module Buildkite
  module Builder
    class Context
      include Definition::Helper

      PIPELINE_DEFINITION_FILE = Pathname.new('pipeline.rb').freeze

      attr_reader :logger
      attr_reader :root
      attr_reader :pipeline
      attr_reader :artifacts

      def self.build(root, logger: nil)
        context = new(root, logger: logger)
        context.build
        context
      end

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
        @artifacts = []
      end

      def build
        unless @pipeline
          @pipeline = Pipelines::Pipeline.new

          load_manifests
          load_templates
          load_processors
          load_pipeline
          run_processors
          upload_artifacts
        end

        @pipeline
      end

      private

      def load_manifests
        Loaders::Manifests.load(root).each do |name, asset|
          Manifest[name] = asset
        end
      end

      def load_templates
        Loaders::Templates.load(root).each do |name, asset|
          pipeline.template(name, &asset)
        end
      end

      def load_processors
        Loaders::Processors.load(root)
      end

      def run_processors
        pipeline.processors.each do |processor|
          processor.process(self)
        end
      end

      def upload_artifacts
        return if artifacts.empty?

        artifacts.each do |file|
          unless [Tempfile, File].any? { |file_type| file.is_a?(file_type) }
            raise "Artifatcs must be an instance of `Tempfile` or `File`, got `#{file.class}` instead."
          end
          Buildkite::Pipelines::Command.artifact!(:upload, file.path)
        end
      end

      def load_pipeline
        pipeline.instance_eval(&pipeline_definition)
      end

      def pipeline_definition
        @pipeline_definition ||= load_definition(root.join(PIPELINE_DEFINITION_FILE), Definition::Pipeline)
      end
    end
  end
end
