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
                  :templates

      def self.build(root, logger: nil)
        pipeline = new(root, logger: logger)
        pipeline.build
      end

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
        @artifacts = []
        @plugins = {}
        @extensions = {}
        @templates = {}
        @built = false
        @data = Data.new(env: {}, notify: [], steps: [])
        @dsl = Dsl.new(self, @data, extensions: true)

        register(Extensions::Env)
        register(Extensions::Notify)
        register(Extensions::Steps)
      end

      def built?
        @built
      end

      def build
        results = benchmark("\nDone (%s)".color(:springgreen)) do
          unless built?
            load_manifests
            load_templates
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

      def plugin(name, uri, version)
        name = name.to_s

        if plugins.key?(name)
          raise ArgumentError, "Plugin already defined: #{name}"
        end

        @plugins[name] = [uri, version]
      end

      def template(name, &definition)
        name = name.to_s

        if @templates.key?(name)
          raise ArgumentError, "Template already defined: #{name}"
        elsif !block_given?
          raise ArgumentError, 'Template definition block must be given'
        end

        @templates[name.to_s] = definition
      end

      def register(extension_class, **args)
        unless extension_class < Buildkite::Builder::Extension
          raise "#{extension_class} must inherit from Buildkite::Builder::Extension"
        end

        @extensions[extension_class.new(self)] = args
        dsl.extend(extension_class.dsl_module)
      end

      def to_h
        @extensions.each do |extension, args|
          extension.build(**args)
        end

        Pipelines::Helpers.sanitize(@data.to_pipeline)
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

      def load_templates
        Loaders::Templates.load(root).each do |name, asset|
          template(name, &asset)
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
