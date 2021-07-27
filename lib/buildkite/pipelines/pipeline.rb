# frozen_string_literal: true

require 'yaml'
require 'pathname'

module Buildkite
  module Pipelines
    class Pipeline < Builder
      attr_reader :plugins, :groups

      def initialize(definition = nil, &block)
        @env = {}
        @plugins = {}
        @groups = []
        @processors = []

        super
      end

      def env(*args)
        if args.empty?
          @env
        elsif args.first.is_a?(Hash)
          @env.merge!(args.first.transform_keys(&:to_s))
        else
          raise ArgumentError, 'value must be hash'
        end
      end

      def plugin(name, uri, version)
        name = name.to_s

        if plugins.key?(name)
          raise ArgumentError, "Plugin already defined: #{name}"
        end

        @plugins[name] = [uri, version]
      end

      def processors(*processor_classes)
        unless processor_classes.empty?
          @processors.clear

          processor_classes.flatten.each do |processor|
            unless processor < Buildkite::Builder::Processors::Abstract
              raise "#{processor} must inherit from Buildkite::Builder::Processors::Abstract"
            end

            @processors << processor
          end
        end

        @processors
      end

      def group(name = nil, &block)
        group = Group.new(name)

        templates.each do |name, definition|
          group.template(name, &definition)
        end

        group.instance_eval(&block)

        @groups << group
      end

      def to_h
        pipeline = {}
        pipeline[:env] = env if env.any?
        pipeline[:notify] = notify if notify.any?
        pipeline[:steps] = groups.any? ? groups.map(&:to_h) : []
        pipeline[:steps] += steps.map(&:to_h)

        Helpers.sanitize(pipeline)
      end

      def to_yaml
        YAML.dump(to_h)
      end
    end
  end
end
