# frozen_string_literal: true

require 'bundler'
require 'pathname'
require 'tempfile'

module Buildkite
  module Builder
    class Runner
      include Definition::Helper
      include LoggingUtils
      using Rainbow

      PIPELINES_PATH = Pathname.new('.buildkite/pipelines').freeze
      PIPELINE_DEFINITION_PATH = Pathname.new('pipeline.rb').freeze

      attr_reader :options

      # This entrypoint is for running on CI. It expects certain environment variables to
      # be set.
      def self.run
        new(
          upload: true,
          pipeline: Buildkite.env.pipeline_slug
        ).run
      end

      def initialize(**options)
        @options = {
          verbose: true,
        }.merge(options)
      end

      def run
        log.info "#{'+++ ' if Buildkite.env}🧰 " + 'Buildkite-builder'.color(:springgreen) + " ─ #{@options[:pipeline].yellow}"

        results = benchmark("\nDone (%s)".color(:springgreen)) do
          load_manifests
          load_templates
          load_processors
          load_pipeline
          run_processors
        end
        log.info results

        upload! if options[:upload]
        # Always return the pipeline.

        pipeline
      end

      def pipeline
        @pipeline ||= Buildkite::Pipelines::Pipeline.new
      end

      def pipeline_definition
        @pipeline_definition ||= begin
          expected = Definition::Pipeline
          load_definition(Buildkite::Builder.root.join(".buildkite/pipelines/#{options[:pipeline]}").join(PIPELINE_DEFINITION_PATH), expected)
        end
      end

      def log
        @log ||= begin
          Logger.new(options[:verbose] ? $stdout : StringIO.new).tap do |lgr|
            lgr.formatter = proc do |_severity, _datetime, _progname, msg|
              "#{msg}\n"
            end
          end
        end
      end

      private

      def upload!
        Tempfile.create(['pipeline', '.yml']) do |file|
          file.sync = true
          file.write(pipeline.to_yaml)

          log.info '+++ :paperclip: Uploading artifact'
          Buildkite::Pipelines::Command.artifact!(:upload, file.path)
          log.info '+++ :pipeline: Uploading pipeline'
          Buildkite::Pipelines::Command.pipeline!(:upload, file.path)
        end
      end

      def load_manifests
        Loaders::Manifests.load(options[:pipeline]).each do |name, asset|
          Manifest[name] = asset
        end
      end

      def load_templates
        Loaders::Templates.load(options[:pipeline]).each do |name, asset|
          pipeline.template(name, &asset)
        end
      end

      def load_processors
        Loaders::Processors.load(options[:pipeline])
      end

      def run_processors
        pipeline.processors.each do |processor|
          processor.process(self)
        end
      end

      def load_pipeline
        pipeline.instance_eval(&pipeline_definition)
      end
    end
  end
end
