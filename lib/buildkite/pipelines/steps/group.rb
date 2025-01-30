# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Group < Abstract
        attribute :label
        attribute :key
        attribute :skip
        attribute :if, as: :condition
        attribute :depends_on, append: true
        attribute :allow_dependency_failure

        attr_reader :steps

        def initialize(pipeline, **args)
          @pipeline = pipeline
          @context = StepContext.new(self, **args)
          @steps = Buildkite::Builder::StepCollection.new
        end

        def method_missing(method_name, ...)
          if @pipeline.dsl.respond_to?(method_name)
            @pipeline.dsl.public_send(method_name, ...)
          else
            super
          end
        end

        def respond_to_missing?(...)
          @pipeline.dsl.respond_to?(...) || super
        end

        def to_h
          super.merge(group: nil, steps: steps.to_definition)
        end
      end
    end
  end
end
