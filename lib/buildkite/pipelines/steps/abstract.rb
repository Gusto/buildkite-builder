# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Abstract
        include Attributes

        attr_reader :pipeline
        attr_reader :template
        attr_reader :data

        def self.to_sym
          name.split('::').last.downcase.to_sym
        end

        def initialize(pipeline, template = nil, **args, &block)
          @pipeline = pipeline
          @template = template
          context = StepContext.new(self, **args)
          @data = context.data

          instance_exec(context, &template) if template
          instance_exec(context, &block) if block_given?
        end
      end
    end
  end
end
