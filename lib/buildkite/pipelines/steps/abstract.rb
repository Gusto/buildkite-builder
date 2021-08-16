# frozen_string_literal: true

require "forwardable"

module Buildkite
  module Pipelines
    module Steps
      class Abstract
        extend Forwardable
        include Attributes

        def_delegator :@context, :data

        attr_reader :template
        attr_reader :step_collection

        def self.to_sym
          name.split('::').last.downcase.to_sym
        end

        def initialize(step_collection, template_name, **args, &block)
          @step_collection = step_collection
          @template = step_collection.templates.find(template_name)
          @context = StepContext.new(self, **args)

          instance_exec(@context, &template) if template
          instance_exec(@context, &block) if block_given?
        end
      end
    end
  end
end
