# frozen_string_literal: true

require 'open3'

module Buildkite
  module Pipelines
    class Command
      BIN_PATH = 'buildkite-agent'
      COMMANDS = %w(
        pipeline
        artifact
        annotate
        meta_data
      )

      class << self
        def pipeline(subcommand, *args)
          new(:pipeline, subcommand, *args).run
        end

        def artifact(subcommand, *args)
          case subcommand.to_s
          when 'shasum', 'search'
            new(:'artifact', subcommand, *args).run(capture: true)
          else
          new(:artifact, subcommand, *args).run
          end
        end

        def annotate(body, *args)
          new(:annotate, body, *args).run
        end

        def meta_data(subcommand, *args)
          case subcommand.to_s
          when 'get', 'keys'
            new(:'meta-data', subcommand, *args).run(capture: true)
          else
            new(:'meta-data', subcommand, *args).run
          end
        end
      end

      COMMANDS.each do |command|
        define_singleton_method("#{command}!") do |*args|
          abort unless public_send(command, *args)
        end
      end

      def initialize(command, subcommand, *args)
        @command = command.to_s
        @subcommand = subcommand.to_s
        @options = extract_options(args)
        @args = transform_args(args)
      end

      def run(capture: false)
        stdout, _, status = Open3.capture3(*to_a)
        capture ? stdout : status.success?
      end

      private

      def to_a
        command = [BIN_PATH, @command, @subcommand]
        command.concat(@options.to_a.flatten)
        command.concat(@args)
      end

      def extract_options(args)
        return {} unless args.first.is_a?(Hash)

        args.shift.tap do |options|
          options.transform_keys! do |key|
            "--#{key.to_s.tr('_', '-')}"
          end
          options.transform_values!(&:to_s)
        end
      end

      def transform_args(args)
        args.map!(&:to_s)
      end
    end
  end
end
