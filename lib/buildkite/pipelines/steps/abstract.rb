# frozen_string_literal: true

require "forwardable"

module Buildkite
  module Pipelines
    module Steps
      class Abstract
        extend Forwardable
        include Attributes

        def_delegator :@context, :data

        attr_reader :pipeline
        attr_reader :template

        def self.to_sym
          name.split('::').last.downcase.to_sym
        end

        def initialize(pipeline, template = nil, **args, &block)
          @pipeline = pipeline
          @template = template
          @context = StepContext.new(self, **args)

          instance_exec(@context, &template) if template
          instance_exec(@context, &block) if block_given?
        end
      end
    end
  end
end
