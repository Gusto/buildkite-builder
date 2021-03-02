require 'logger'
require 'tempfile'

module Buildkite
  module Builder
    class Context
      include Definition::Helper
      include LoggingUtils
      using Rainbow

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
        results = benchmark("\nDone (%s)".color(:springgreen)) do
          unless @pipeline
            @pipeline = Pipelines::Pipeline.new

            load_manifests
            load_templates
            load_processors
            load_pipeline
            run_processors
          end
        end
        logger.info(results)

        @pipeline
      end

      def upload
        build unless @pipeline

        logger.info '+++ :paperclip: Uploading artifacts'
        upload_artifacts

        # Upload the pipeline.
        Tempfile.create(['pipeline', '.yml']) do |file|
          file.sync = true
          file.write(pipeline.to_yaml)

          logger.info '+++ :paperclip: Uploading pipeline.yml as artifact'
          Buildkite::Pipelines::Command.artifact!(:upload, file.path)
          logger.info '+++ :pipeline: Uploading pipeline'
          Buildkite::Pipelines::Command.pipeline!(:upload, file.path)
        end
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

        artifacts.each do |path|
          if File.exist?(path)
            Buildkite::Pipelines::Command.artifact!(:upload, path)
          end
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
