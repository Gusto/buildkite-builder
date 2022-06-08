require 'securerandom'

module Buildkite
  module Builder
    module Extensions
      class SubPipelines < Extension
        class Pipeline
          include Buildkite::Pipelines::Attributes

          attr_reader :data, :name

          attribute :depends_on, append: true
          attribute :key

          def self.to_sym
            name.split('::').last.downcase.to_sym
          end

          def initialize(name, steps, &block)
            @name = name
            @data = Data.new
            @data.steps = StepCollection.new(
              steps.templates,
              steps.plugins
            )
            @data.notify = []
            @data.env = {}

            @dsl = Dsl.new(self)
            @dsl.extend(Extensions::Steps)
            @dsl.extend(Extensions::Notify)
            @dsl.extend(Extensions::Env)
            instance_eval(&block) if block_given?
            self
          end

          def to_h
            attributes = super
            attributes.merge(data.to_definition)
          end

          def method_missing(method_name, *args, **kwargs, &_block)
            @dsl.public_send(method_name, *args, **kwargs, &_block)
          end

          def pipeline_yml
            @pipeline_yml ||= "tmp/buildkite-builder/#{SecureRandom.urlsafe_base64}.yml"
          end
        end

        def prepare
          context.data.pipelines = PipelineCollection.new(context.artifacts)
        end

        dsl do
          def pipeline(name, template = nil, &block)
            raise "Subpipeline must have a name" if name.empty?
            raise "Subpipeline does not allow nested in another Subpipeline" if context.is_a?(Buildkite::Builder::Extensions::SubPipelines::Pipeline)
            sub_pipeline = Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(name, context.data.steps, &block)

            context.data.pipelines.add(sub_pipeline)

            if template
              # Use predefined template
              step = context.data.steps.add(Pipelines::Steps::Trigger, template)

              if step.build.nil?
                step.build(env: { BKB_SUBPIPELINE_FILE: sub_pipeline.pipeline_yml })
              else
                step.build[:env].merge!(BKB_SUBPIPELINE_FILE: sub_pipeline.pipeline_yml)
              end
            else
              # Generic trigger step
              context.data.steps.add(Pipelines::Steps::Trigger, key: "subpipeline_#{name}_#{context.data.pipelines.count}") do |context|
                key context[:key]
                label name.capitalize
                trigger name
                build(
                  message: '${BUILDKITE_MESSAGE}',
                  commit: '${BUILDKITE_COMMIT}',
                  branch: '${BUILDKITE_BRANCH}',
                  env: {
                    BUILDKITE_PULL_REQUEST: '${BUILDKITE_PULL_REQUEST}',
                    BUILDKITE_PULL_REQUEST_BASE_BRANCH: '${BUILDKITE_PULL_REQUEST_BASE_BRANCH}',
                    BUILDKITE_PULL_REQUEST_REPO: '${BUILDKITE_PULL_REQUEST_REPO}',
                    BKB_SUBPIPELINE_FILE: sub_pipeline.pipeline_yml
                  }
                )
              end
            end
          end
        end
      end
    end
  end
end
