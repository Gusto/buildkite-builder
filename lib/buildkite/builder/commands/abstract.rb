# frozen_string_literal: true

require 'optparse'

module Buildkite
  module Builder
    module Commands
      class Abstract
        PIPELINES_DIRECTORY = 'pipelines'
        POSSIBLE_PIPELINE_PATHS = [
          File.join('.buildkite', Context::PIPELINE_DEFINITION_FILE),
          File.join('buildkite', Context::PIPELINE_DEFINITION_FILE),
          File.join(Context::PIPELINE_DEFINITION_FILE)
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
          elsif !pipeline_root_path
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
          # noop
          # Subclasses should override to parse options.
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

        def pipeline_root_path
          @pipeline_root_path ||=
            find_root_by_environment ||
            find_root_by_main_pipeline ||
            find_root_by_multi_pipeline
        end

        def find_root_by_environment
          if ENV['BUILDKITE_ROOT']
            path = Pathname.new(ENV['BUILDKITE_ROOT'])
            path.absolute? ? path : Builder.root.join(path)
          end
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
      end
    end
  end
end
