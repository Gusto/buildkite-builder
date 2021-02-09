# frozen_string_literal: true

require 'optparse'

module Buildkite
  module Builder
    module Commands
      class Abstract
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
          end

          run
        end

        private

        def command_name
          Commands::COMMANDS.key(self.class.name.split('::').last.to_sym)
        end

        def parse_options(opts)
          # noop
          # Subclasses should override to parse options.
        end

        def available_pipelines
          @available_pipelines ||= pipelines_path.children.select(&:directory?).map { |dir| dir.basename.to_s }
        end

        def pipelines_path
          Builder.root.join(Builder::BUILDKITE_DIRECTORY_NAME).join(Runner::PIPELINES_PATH)
        end
      end
    end
  end
end
