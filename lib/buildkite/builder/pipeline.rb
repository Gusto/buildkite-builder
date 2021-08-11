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
                  :pipeline_dsl,
                  :env,
                  :templates,
                  :notify,
                  :steps,
                  :groups

      def self.build(root, logger: nil)
        pipeline = new(root, logger: logger)
        pipeline.build
      end

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
        @artifacts = []
        @plugins = {}
        @processors = {}
        @env = {}
        @templates = {}
        @steps = []
        @notify = []
        @groups = []
        @built = false
        @pipeline_dsl = Dsl::Pipeline.new(self)
      end

      def built?
        @built
      end

      def build
        results = benchmark("\nDone (%s)".color(:springgreen)) do
          unless built?
            load_manifests
            load_templates
            load_processors
            pipeline_dsl.instance_eval(&pipeline_definition)
            run_processors
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

      def use(processor, **args)
        unless processor < Buildkite::Builder::Processors::Abstract
          raise "#{processor} must inherit from Buildkite::Builder::Processors::Abstract"
        end

        @processors[processor.new(self)] = args
      end

      def to_h
        pipeline_data = {}
        pipeline_data[:env] = env if env.any?
        pipeline_data[:notify] = notify if notify.any?
        if groups.any?
          pipeline_data[:steps] = groups.map do |group|
            { group: group[:group], steps: group[:steps].map(&:to_h) }
          end

          pipeline_data[:steps] += steps.map(&:to_h)
        else
          pipeline_data[:steps] = steps.map(&:to_h)
        end

        Pipelines::Helpers.sanitize(pipeline_data)
      end

      def to_yaml
        YAML.dump(to_h)
      end

      def compose(&block)
        pipeline_dsl.instance_eval(&block)
      end

      private

      def load_manifests
        Loaders::Manifests.load(root).each do |name, asset|
          Manifest[name] = asset
        end
      end

      def load_templates
        Loaders::Templates.load(root).each do |name, asset|
          pipeline_dsl.template(name, &asset)
        end
      end

      def load_processors
        Loaders::Processors.load(root)
      end

      def run_processors
        @processors.each do |processor, args|
          processor.run(**args)
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
        pipeline_dsl.instance_eval(&pipeline_definition)
      end

      def pipeline_definition
        @pipeline_definition ||= load_definition(root.join(PIPELINE_DEFINITION_FILE), Definition::Pipeline)
      end
    end
  end
end
