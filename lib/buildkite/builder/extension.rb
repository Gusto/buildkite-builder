# frozen_string_literal: true

module Buildkite
  module Builder
    class Extension
      include LoggingUtils
      using Rainbow

      class << self
        attr_reader :dsl

        def dsl(&block)
          @dsl = Module.new(&block) if block_given?
          @dsl
        end
      end

      attr_reader :context
      attr_reader :options

      def initialize(context, **options)
        @context = context
        @options = options

        prepare
      end

      def _build
        _log_run { build(**options) }
      end

      def build
        # Override to provide extra functionality.
      end

      def log
        context.logger
      end

      def buildkite
        @buildkite ||= begin
          unless Buildkite.env
            raise 'Must be in Buildkite environment to access the Buildkite API'
          end

          Buildkite::Pipelines::Api.new(Buildkite.env.api_token)
        end
      end

      private

      def prepare
        # Override to provide extra functionality.
      end

      def pipeline(&block)
        context.dsl.instance_eval(&block) if block_given?
        context
      end

      def _log_run
        log.info "\nProcessing ".color(:dimgray) + self.class.name.color(:springgreen)

        results = benchmark('└──'.color(:springgreen) + ' Finished in %s'.color(:dimgray)) do
          formatter = log.formatter
          log.formatter = proc do |_severity, _datetime, _progname, msg|
            '│'.color(:springgreen) + " #{msg}\n"
          end

          begin
            yield
          ensure
            log.formatter = formatter
          end
        end

        log.info results
      end
    end
  end
end
