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

      attr_reader :logger, :root, :artifacts, :steps, :plugins, :templates, :processors

      def self.build(root, logger: nil)
        pipeline = new(root, logger: logger)
        pipeline.build
      end

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
        @artifacts = []
        @env = {}
        @steps = []
        @plugins = {}
        @templates = {}
        @processors = []
        @notify = []
        @built = false
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
            load_pipeline
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

      [
        Pipelines::Steps::Block,
        Pipelines::Steps::Command,
        Pipelines::Steps::Input,
        Pipelines::Steps::Trigger,
      ].each do |type|
        define_method(type.to_sym) do |template = nil, **args, &block|
          add(type, template, **args, &block)
        end
      end

      def notify(*args)
        if args.empty?
          @notify
        elsif args.first.is_a?(Hash)
          @notify.push(args.first.transform_keys(&:to_s))
        else
          raise ArgumentError, 'value must be hash'
        end
      end

      def env(*args)
        if args.empty?
          @env
        elsif args.first.is_a?(Hash)
          @env.merge!(args.first.transform_keys(&:to_s))
        else
          raise ArgumentError, 'value must be hash'
        end
      end

      def skip(template = nil, **args, &block)
        step = add(Pipelines::Steps::Skip, template, **args, &block)
        # A skip step has a nil/noop command.
        step.command(nil)
        # Always set the skip attribute if it's in a falsey state.
        step.skip(true) if !step.get(:skip) || step.skip.empty?
        step
      end

      def wait(attributes = {}, &block)
        step = add(Pipelines::Steps::Wait, &block)
        step.wait(nil)
        attributes.each do |key, value|
          step.set(key, value)
        end
        step
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

        if templates.key?(name)
          raise ArgumentError, "Template already defined: #{name}"
        elsif !block_given?
          raise ArgumentError, 'Template definition block must be given'
        end

        @templates[name.to_s] = definition
      end

      def use(processor, **args)
        unless processor < Buildkite::Builder::Processors::Abstract
          raise "#{processor} must inherit from Buildkite::Builder::Processors::Abstract"
        end

        @processors << processor.new(self, **args)
      end

      def to_h
        pipeline_data = {}
        pipeline_data[:env] = env if env.any?
        pipeline_data[:notify] = notify if notify.any?
        pipeline_data[:steps] = steps.map(&:to_h)

        Pipelines::Helpers.sanitize(pipeline_data)
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

      def load_processors
        Loaders::Processors.load(root)
      end

      def run_processors
        processors.each do |processor|
          processor.run
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
        instance_eval(&pipeline_definition)
      end

      def pipeline_definition
        @pipeline_definition ||= load_definition(root.join(PIPELINE_DEFINITION_FILE), Definition::Pipeline)
      end

      def add(step_class, template = nil, **args, &block)
        steps.push(step_class.new(self, find_template(template), **args, &block)).last
      end

      def find_template(name)
        return unless name

        templates[name.to_s] || begin
          raise ArgumentError, "Template not defined: #{name}"
        end
      end
    end
  end
end
