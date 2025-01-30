# frozen_string_literal: true

require "forwardable"

module Buildkite
  module Pipelines
    module Steps
      class Abstract
        extend Forwardable
        include Attributes

        def_delegator :@context, :data

        def self.to_sym
          name.split('::').last.downcase.to_sym
        end

        def initialize(**args)
          @context = StepContext.new(self, **args)
        end

        def process(block)
          instance_exec(@context, &block)
        end
      end
    end
  end
end
