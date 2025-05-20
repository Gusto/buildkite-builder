# frozen_string_literal: true

module Buildkite
  module Builder
    class Extension
      autoload :Template, File.expand_path('extension/template', __dir__)

      class << self
        def dsl(&block)
          @dsl = Module.new(&block) if block_given?
          @dsl
        end

        def template(name = :default, &block)
          name = name.to_s

          if block_given? && templates.key?(name)
            raise ArgumentError, "Template #{name} already registered in #{self.name}"
          end

          templates[name] ||= Template.new(self, name, block)
        end

        def templates
          @templates ||= {}
        end
      end

      attr_reader :context
      attr_reader :options
      attr_reader :options_block

      def initialize(context, **options, &block)
        @context = context
        @options = options
        @options_block = block

        prepare
      end

      def build
        # Override to provide extra functionality.
      end

      private

      def log
        context.logger
      end

      def prepare
        # Override to provide extra functionality.
      end

      def pipeline(&block)
        context.dsl.instance_eval(&block)
      end
    end
  end
end
