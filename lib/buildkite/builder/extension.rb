# frozen_string_literal: true

module Buildkite
  module Builder
    class Extension
      class Template
        attr_reader :extension_class, :name, :block

        def initialize(extension_class, name, block)
          @extension_class = extension_class
          @name = name
          @block = block
        end
      end

      class << self
        def dsl(&block)
          @dsl = Module.new(&block) if block_given?
          @dsl
        end

        def template(name = :default, &block)
          @templates ||= {}
          @templates[name.to_s] ||= Template.new(self, name, block)
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

      def get_template(name = :default)
        self.class.templates[name.to_s]
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
