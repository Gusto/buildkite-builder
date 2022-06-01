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

            @dsl = Dsl.new(self)
            @dsl.extend(Extensions::Steps)
            @dsl.extend(Extensions::Notify)
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
        end

        def prepare
          context.data.pipelines = PipelineCollection.new(context.artifacts)
        end

        dsl do
          def pipeline(name, trigger: true, &block)
            raise "Subpipeline must have a name" if name.empty?
            raise "Subpipeline does not allow nested in another Subpipeline" if context.is_a?(Buildkite::Builder::Extensions::SubPipelines::Pipeline)

            triggered_pipeline = case trigger
              when TrueClass then name
              when String then trigger
            end

            context.data.pipelines.add(Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(name, context.data.steps, &block))

            if triggered_pipeline
              template = begin
                context.data.steps.templates.find(triggered_pipeline)
              rescue ArgumentError
                nil
              end

              if template
                # Use predefined template
                context.data.steps.add(Pipelines::Steps::Trigger, template)
              else
                # Generic trigger step
                context.data.steps.add(Pipelines::Steps::Trigger) do
                  key :"trigger_#{triggered_pipeline}"
                  label triggered_pipeline.capitalize
                  trigger triggered_pipeline
                  build(
                    message: '${BUILDKITE_MESSAGE}',
                    commit: '${BUILDKITE_COMMIT}',
                    branch: '${BUILDKITE_BRANCH}',
                    env: {
                      BUILDKITE_PULL_REQUEST: '${BUILDKITE_PULL_REQUEST}',
                      BUILDKITE_PULL_REQUEST_BASE_BRANCH: '${BUILDKITE_PULL_REQUEST_BASE_BRANCH}',
                      BUILDKITE_PULL_REQUEST_REPO: '${BUILDKITE_PULL_REQUEST_REPO}'
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
end
