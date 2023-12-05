# frozen_string_literal: true

require 'open3'

module Buildkite
  module Pipelines
    class Command
      class CommandFailedError < StandardError; end

      class Result
        attr_reader :stdout, :stderr
        def initialize(stdout, stderr, status)
          @stdout = stdout.strip
          @stderr = stderr.strip
          @status = status
        end

        def success?
          @status.success?
        end

        def output
          @output ||= "#{stdout}\n#{stderr}".strip
        end
      end

      BIN_PATH = 'buildkite-agent'
      COMMANDS = %w(
        pipeline
        artifact
        annotate
        meta_data
      )

      class << self
        def pipeline(subcommand, *args, exception: false)
          new(:pipeline, subcommand, *args).run(exception: exception)
        end

        def artifact(subcommand, *args, exception: false)
          result = new(:artifact, subcommand, *args).run(exception: exception)

          case subcommand.to_s
          when 'shasum', 'search' then result.output
          else result.success?
          end
        end

        def annotate(body, *args, exception: false)
          new(:annotate, body, *args).run(exception: exception)
        end

        def meta_data(subcommand, *args, exception: false)
          result = new(:'meta-data', subcommand, *args).run(exception: exception)

          case subcommand.to_s
          when 'get', 'keys' then result.output
          else result.success?
          end
        end
      end

      COMMANDS.each do |command|
        define_singleton_method("#{command}!") do |*args|
          public_send(command, *args, exception: true)
        rescue CommandFailedError => e
          abort e.message
        end
      end

      def initialize(command, subcommand, *args)
        @command = command.to_s
        @subcommand = subcommand.to_s
        @options = extract_options(args)
        @args = transform_args(args)
      end

      def run(exception: false)
        stdout, stderr, status = Open3.capture3(*to_a)
        result = Result.new(stdout, stderr, status)

        if !result.success? && exception
          raise CommandFailedError, "#{result.output}"
        else
          result
        end
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
