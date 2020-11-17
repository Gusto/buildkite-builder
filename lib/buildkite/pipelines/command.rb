# frozen_string_literal: true

module Buildkite
  module Pipelines
    class Command
      BIN_PATH = 'buildkite-agent'

      def self.pipeline!(*args)
        abort unless pipeline(*args)
      end

      def self.pipeline(subcommand, *args)
        new(:pipeline, subcommand, *args).run
      end

      def self.artifact!(*args)
        abort unless artifact(*args)
      end

      def self.artifact(subcommand, *args)
        new(:artifact, subcommand, *args).run
      end

      def initialize(command, subcommand, *args)
        @command = command.to_s
        @subcommand = subcommand.to_s
        @options = extract_options(args)
        @args = transform_args(args)
      end

      def run
        system(*to_a)
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
