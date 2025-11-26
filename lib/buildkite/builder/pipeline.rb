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
                  :dsl,
                  :data,
                  :extensions

      def initialize(root, logger: nil)
        @root = root
        @logger = logger || Logger.new(File::NULL)
        @artifacts = []
        @dsl = Dsl.new(self)
        @extensions = ExtensionManager.new(self)
        @data = Data.new

        use(Extensions::Use)
        use(Extensions::Lib)
        use(Extensions::Env)
        use(Extensions::Notify)
        use(Extensions::Steps)
        use(Extensions::Plugins)
        use(Extensions::Agents)
      end

      def upload
        # Generate the pipeline YAML first.
        contents = to_yaml

        upload_artifacts

        if data.steps.empty?
          logger.info "+++ :pipeline: No steps defined, skipping pipeline upload"
        else
          # Upload the pipeline.
          Tempfile.create(['pipeline', '.yml']) do |file|
            file.sync = true
            file.write(contents)

            logger.info "+++ :pipeline: Uploading pipeline"

            result = Buildkite::Pipelines::Command.pipeline(:upload, file.path)

            unless result.success?
              logger.info "Pipeline upload failed with #{result.stderr}, saving as artifact…"
              Buildkite::Pipelines::Command.artifact!(:upload, file.path)
              abort
            end
          end
        end

        # Use pipeline-specific metadata key instead of generic job metadata
        logger.info "+++ :toolbox: Setting job meta-data #{pipeline_metadata_key.color(:yellow)} to #{Buildkite.env.step_id.color(:yellow)}"
        Buildkite::Pipelines::Command.meta_data!(:set, pipeline_metadata_key, Buildkite.env.step_id)
      end

      # Check if this specific pipeline has already been uploaded
      def already_uploaded?
        Buildkite::Pipelines::Command.meta_data(:exists, pipeline_metadata_key).success?
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

      def pipeline_metadata_key
        @pipeline_metadata_key ||= begin
          # Create a unique metadata key based on the pipeline path
          # This allows multiple pipelines to be uploaded in the same step
          relative_path = root.relative_path_from(Builder.root)
          path_key = relative_path.to_s.gsub(/[^a-zA-Z0-9]/, '_').gsub(/_+/, '_').gsub(/^_|_$/, '')
          "buildkite_builder_uploaded_#{path_key}"
        end
      end

      def upload_artifacts
        return if artifacts.empty?

        logger.info "+++ :paperclip: Uploading artifacts"
        Buildkite::Pipelines::Command.artifact!(:upload, artifacts.join(";"))
      end

      def pipeline_definition
        @pipeline_definition ||= load_definition(root.join(PIPELINE_DEFINITION_FILE), Definition::Pipeline)
      end
    end
  end
end
