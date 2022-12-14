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

        def process(block)
          super

          upload_detached_pipeline if detached
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

        def upload_detached_pipeline
          contents = YAML.dump(to_h)

          # Clear steps and put a placeholder
          @steps = Buildkite::Builder::StepCollection.new
          skip_step = Buildkite::Pipelines::Steps::Skip.new.tap { |step| step.skip(true) }
          steps.push(skip_step)

          Tempfile.create([SecureRandom.urlsafe_base64, '.yml']) do |file|
            file.sync = true
            file.write(contents)

            @pipeline.logger.info "+++ :pipeline: Uploading detached group"
            unless Buildkite::Pipelines::Command.pipeline(:upload, file.path)
              logger.info "Pipeline upload failed, saving as artifact…"
              Buildkite::Pipelines::Command.artifact!(:upload, file.path)
              abort
            end
          end
        end
      end
    end
  end
end
