# frozen_string_literal: true

require 'bundler'
require 'pathname'
require 'tempfile'
require 'logger'

module Buildkite
  module Builder
    class Runner
      include LoggingUtils
      using Rainbow

      PIPELINES_PATH = Pathname.new('pipelines').freeze

      attr_reader :options


      def initialize(**options)
        @options = options
      end

      def run
        log.info "#{'+++ ' if Buildkite.env}🧰 " + 'Buildkite-builder'.color(:springgreen) + " ─ #{@options[:pipeline].yellow}"
        context = Context.new(root, logger: log)

        results = benchmark("\nDone (%s)".color(:springgreen)) do
          context.build
        end
        log.info(results)

        if options[:upload]
          upload(context.pipeline)
        end

        # Always return the pipeline.
        context.pipeline
      end

      def log
        @log ||= begin
          Logger.new($stdout).tap do |logger|
            logger.formatter = proc do |_severity, _datetime, _progname, msg|
              "#{msg}\n"
            end
          end
        end
      end

      private

      def upload(pipeline)
        Tempfile.create(['pipeline', '.yml']) do |file|
          file.sync = true
          file.write(pipeline.to_yaml)

          log.info '+++ :paperclip: Uploading artifact'
          Buildkite::Pipelines::Command.artifact!(:upload, file.path)
          log.info '+++ :pipeline: Uploading pipeline'
          Buildkite::Pipelines::Command.pipeline!(:upload, file.path)
        end
      end

      def root
        @root ||= begin
          path = Builder.root.join(Builder::BUILDKITE_DIRECTORY_NAME)
          if options[:pipeline]
            pipeline_path = path.join(PIPELINES_PATH).join(options[:pipeline])
            if pipeline_path.directory?
              path = pipeline_path
            end
          end
          path
        end
      end
    end
  end
end
