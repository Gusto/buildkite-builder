require 'logger'
require 'tempfile'
require 'yaml'
require 'pathname'
require 'forwardable'

module Buildkite
  module Builder
    class Pipeline
      extend Forwardable
      include Definition::Helper
      include LoggingUtils
      using Rainbow

      PIPELINE_DEFINITION_FILE = Pathname.new('pipeline.rb').freeze

      def_delegator :@extensions, :use

      attr_reader :logger,
                  :root,
                  :artifacts,
                  :plugins,
                  :dsl,
                  :data

      def self.build(root, logger: nil)
        new(root, logger: logger)
      end

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
        @artifacts = []
        @plugins = {}
        @dsl = Dsl.new(self)
        @extensions = ExtensionManager.new(self)
        @data = Data.new

        use(Extensions::Use)
        use(Extensions::Env)
        use(Extensions::Notify)
        use(Extensions::Steps)
        load_manifests
      end

      def upload
        logger.info '+++ :paperclip: Uploading artifacts'
        upload_artifacts

        # Upload the pipeline.
        Tempfile.create(['pipeline', '.yml']) do |file|
          file.sync = true
          file.write(to_yaml)

          logger.info '+++ :paperclip: Uploading pipeline.yml as artifact'
          Buildkite::Pipelines::Command.artifact!(:upload, file.path)
          logger.info '+++ :pipeline: Uploading pipeline'
          Buildkite::Pipelines::Command.pipeline!(:upload, file.path)
        end
      end

      def to_h
        @pipeline_hash ||= begin
          results = benchmark("\nDone (%s)".color(:springgreen)) do
            dsl.instance_eval(&pipeline_definition)
            extensions.build
          end
          logger.info(results)
          # Build the pipeline definition from pipeline data.
          Pipelines::Helpers.sanitize(data.to_definition)
        end
      end

      def to_yaml
        YAML.dump(to_h)
      end

      private

      attr_reader :extensions

      def load_manifests
        Loaders::Manifests.load(root).each do |name, asset|
          Manifest[name] = asset
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

      def pipeline_definition
        @pipeline_definition ||= load_definition(root.join(PIPELINE_DEFINITION_FILE), Definition::Pipeline)
      end
    end
  end
end
