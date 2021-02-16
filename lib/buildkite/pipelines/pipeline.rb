# frozen_string_literal: true

require 'yaml'
require 'pathname'

module Buildkite
  module Pipelines
    class Pipeline
      attr_reader :steps
      attr_reader :plugins
      attr_reader :templates

      def initialize(definition = nil, &block)
        @env = {}
        @steps = []
        @plugins = {}
        @templates = {}
        @processors = []
        @notify = []

        instance_eval(&definition) if definition
        instance_eval(&block) if block_given?
      end

      [
        Steps::Block,
        Steps::Command,
        Steps::Input,
        Steps::Trigger,
      ].each do |type|
        define_method(type.to_sym) do |template = nil, **args, &block|
          add(type, template, **args, &block)
        end
      end

      def notify(*args)
        if args.empty?
          @notify
        elsif args.first.is_a?(Hash)
          @notify.push(args.first.transform_keys(&:to_s))
        else
          raise ArgumentError, 'value must be hash'
        end
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

      def skip(template = nil, **args, &block)
        step = add(Steps::Skip, template, **args, &block)
        # A skip step has a nil/noop command.
        step.command(nil)
        # Always set the skip attribute if it's in a falsey state.
        step.skip(true) if !step.get(:skip) || step.skip.empty?
        step
      end

      def wait(attributes = {}, &block)
        step = add(Steps::Wait, &block)
        step.wait(nil)
        attributes.each do |key, value|
          step.set(key, value)
        end
        step
      end

      def plugin(name, uri, version)
        name = name.to_s

        if plugins.key?(name)
          raise ArgumentError, "Plugin already defined: #{name}"
        end

        @plugins[name] = [uri, version]
      end

      def template(name, &definition)
        name = name.to_s

        if templates.key?(name)
          raise ArgumentError, "Template already defined: #{name}"
        elsif !block_given?
          raise ArgumentError, 'Template definition block must be given'
        end

        @templates[name.to_s] = definition
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

      def to_h
        pipeline = {}
        pipeline[:env] = env if env.any?
        pipeline[:notify] = notify if notify.any?
        pipeline[:steps] = steps.map(&:to_h)

        Helpers.sanitize(pipeline)
      end

      def to_yaml
        YAML.dump(to_h)
      end

      private

      def add(step_class, template = nil, **args, &block)
        steps.push(step_class.new(self, find_template(template), **args, &block)).last
      end

      def find_template(name)
        return unless name

        templates[name.to_s] || begin
          raise ArgumentError, "Template not defined: #{name}"
        end
      end
    end
  end
end
