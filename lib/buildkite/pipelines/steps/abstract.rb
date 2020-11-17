# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Abstract
        include Attributes

        attr_reader :pipeline
        attr_reader :template

        def self.to_sym
          name.split('::').last.downcase.to_sym
        end

        def initialize(pipeline, template = nil, &block)
          @pipeline = pipeline
          @template = template

          instance_eval(&template) if template
          instance_eval(&block) if block_given?
        end
      end
    end
  end
end
