require 'logger'
require 'tempfile'
require 'yaml'
require 'pathname'

module Buildkite
  module Builder
    class Pipeline
      include Definition::Helper
      include LoggingUtils
      using Rainbow

      PIPELINE_DEFINITION_FILE = Pathname.new('pipeline.rb').freeze

      attr_reader :logger,
                  :root,
                  :artifacts,
                  :plugins,
                  :dsl,
                  :data

      def self.build(root, logger: nil)
        pipeline = new(root, logger: logger)
        pipeline.build
      end

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
        @artifacts = []
        @plugins = {}
        @extensions = []
        @built = false
        @data = Data.new
        @dsl = Dsl.new(self)

        use(Extensions::Use)
        use(Extensions::Env)
        use(Extensions::Notify)
        use(Extensions::Steps)
      end

      def built?
        @built
      end

      def build
        results = benchmark("\nDone (%s)".color(:springgreen)) do
          unless built?
            load_manifests
            load_extensions
            dsl.instance_eval(&pipeline_definition)
          end
        end
        logger.info(results)
        @built = true
        self
      end

      def upload
        build unless built?

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

      def use(extension_class, **args)
        unless extension_class < Buildkite::Builder::Extension
          raise "#{extension_class} must inherit from Buildkite::Builder::Extension"
        end

        @extensions.push(extension_class.new(self, **args))
        dsl.extend(extension_class)
      end

      def to_h
        # Build all extensions.
        @extensions.each(&:_build)

        # Build the pipeline definition from pipeline data.
        Pipelines::Helpers.sanitize(data.to_definition)
      end

      def to_yaml
        YAML.dump(to_h)
      end

      private

      def load_manifests
        Loaders::Manifests.load(root).each do |name, asset|
          Manifest[name] = asset
        end
      end

      def load_extensions
        Loaders::Extensions.load(root)
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
