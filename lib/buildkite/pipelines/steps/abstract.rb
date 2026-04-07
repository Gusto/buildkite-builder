# frozen_string_literal: true

require "forwardable"

module Buildkite
  module Pipelines
    module Steps
      class Abstract
        extend Forwardable
        include Attributes

        def_delegators :@context, :data, :source_location

        def self.to_sym
          name.split('::').last.downcase.to_sym
        end

        def initialize(**args)
          @context = StepContext.new(self, **args)
        end

        def process(block)
          file, line = block.source_location
          @context.source_location = SourceLocation.new(file: file, line_number: line) if file
          instance_exec(@context, &block)
        end
      end
    end
  end
end
