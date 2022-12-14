# frozen_string_literal: true

require 'securerandom'

module Buildkite
  module Pipelines
    module Steps
      class Group < Abstract
        attribute :depends_on, append: true
        attribute :key
        attribute :label

        attr_reader \
          :steps,
          :detached

        def initialize(pipeline, detached: false, **args)
          @pipeline = pipeline
          @detached = detached
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
          result = super.merge(group: nil, steps: steps.to_definition)

          if detached
            append_detached_pipeline(result)
            super.merge(group: nil, steps: [{ command: 'true', skip: 'true', label: ':toolbox' }])
          else
            result
          end
        end

        def append_detached_pipeline(result)
          contents = YAML.dump(result)

          file = Pathname.new("tmp/#{SecureRandom.urlsafe_base64}.yml")
          file.dirname.mkpath
          file.write(YAML.dump(Buildkite::Pipelines::Helpers.sanitize(pipeline.to_h)))

          pipeline.detached_groups << file
        end
      end
    end
  end
end
