# frozen_string_literal: true

module Buildkite
  module Pipelines
    class Builder
      attr_reader :steps, :templates

      def initialize(definition = nil, &block)
        @steps = []
        @plugins = {}
        @templates = {}
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

      def template(name, &definition)
        name = name.to_s

        if templates.key?(name)
          raise ArgumentError, "Template already defined: #{name}"
        elsif !block_given?
          raise ArgumentError, 'Template definition block must be given'
        end

        @templates[name.to_s] = definition
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
