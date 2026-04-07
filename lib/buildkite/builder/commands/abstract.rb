# frozen_string_literal: true

require 'optparse'

module Buildkite
  module Builder
    module Commands
      class Abstract
        using Rainbow

        PIPELINES_DIRECTORY = 'pipelines'
        POSSIBLE_PIPELINE_PATHS = [
          File.join('.buildkite', Pipeline::PIPELINE_DEFINITION_FILE),
          File.join('buildkite', Pipeline::PIPELINE_DEFINITION_FILE),
          File.join(Pipeline::PIPELINE_DEFINITION_FILE)
        ].freeze
        POSSIBLE_PIPELINES_PATHS = [
          File.join('.buildkite', PIPELINES_DIRECTORY),
          File.join('buildkite', PIPELINES_DIRECTORY),
          File.join(PIPELINES_DIRECTORY)
        ].freeze

        class << self
          attr_accessor :description

          def execute
            new.execute
          end
        end

        attr_reader :options

        def initialize
          @options = {}

          parser = OptionParser.new do |opts|
            opts.banner = "Usage: buildkite-builder #{command_name} [OPTIONS] [PIPELINE]"

            opts.on('-h', '--help', 'Prints this help') do
              options[:help] = opts
            end

            parse_options(opts)
          end
          parser.parse!
        end

        def execute
          if options[:help]
            puts options[:help]
            return
          elsif !pipeline_path
            abort "Unable to find pipeline"
          end

          run
        end

        private

        def pipeline_slug
          ARGV.last || Buildkite.env&.pipeline_slug
        end

        def command_name
          Commands::COMMANDS.key(self.class.name.split('::').last.to_sym)
        end

        def parse_options(opts)
          opts.on('--no-validate', 'Skip schema validation') do
            options[:no_validate] = true
          end

          opts.on('--strict', 'Fail on validation errors (will be the default in the next major release)') do
            options[:strict] = true
          end
        end

        def validate_pipeline(pipeline)
          return if options[:no_validate]

          enforce_strict_default_migration!

          errors = Validator.new.validate_all(pipeline.to_h, pipeline.steps)
          return if errors.empty?

          errors.each { |error| $stderr.puts error.to_s }

          if options[:strict]
            abort "Pipeline validation failed with #{errors.size.to_s.yellow} error(s)."
          else
            $stderr.puts "Pipeline validation produced #{errors.size.to_s.yellow} warning(s)."
            $stderr.puts "Pass --strict to fail on validation errors. This will become the default in the next major release.".color(:dimgray)
          end
        end

        # Raise at development time when the major version increments, so we
        # remember to flip the default from warn to strict.
        def enforce_strict_default_migration!
          major = Buildkite::Builder.version.split('.').first.to_i
          if major >= 5
            raise "buildkite-builder v#{Buildkite::Builder.version}: validation now defaults to warn mode. " \
                  "Flip the default to strict and remove this guard. See #{__FILE__}:#{__LINE__}."
          end
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

        def pipeline_path
          @pipeline_path ||=
            find_root_by_env_path ||
            find_root_by_main_pipeline ||
            find_root_by_multi_pipeline
        end

        def find_root_by_main_pipeline
          POSSIBLE_PIPELINE_PATHS.map { |path| Builder.root.join(path) }.find(&:exist?)&.dirname
        end

        def find_root_by_multi_pipeline
          pipelines_path = POSSIBLE_PIPELINES_PATHS.map { |path| Builder.root.join(path) }.find(&:directory?)

          if pipelines_path
            if pipeline_slug
              path = pipelines_path.join(pipeline_slug)
              path if path.directory?
            elsif pipelines_path.children.one?
              pipelines_path.children.first
            else
              raise 'Your project has multiple pipelines, please specify one.'
            end
          end
        end

        def find_root_by_env_path
          if ENV['BUILDKITE_BUILDER_PIPELINE_PATH']
            path = Pathname.new(ENV['BUILDKITE_BUILDER_PIPELINE_PATH'])
            path.absolute? ? path : Builder.root.join(path)
          end
        end
      end
    end
  end
end
