require 'securerandom'

module Buildkite
  module Builder
    module Extensions
      class SubPipelines < Extension
        class Pipeline
          include Buildkite::Pipelines::Attributes

          attr_reader \
            :data,
            :name,
            :extensions,
            :root,
            :dsl,
            :context

          # These attributes are for triggered step
          attribute :label
          attribute :key
          attribute :skip
          attribute :if, as: :condition
          attribute :depends_on, append: true
          attribute :allow_dependency_failure
          attribute :branches
          attribute :async
          attribute :build

          def self.to_sym
            name.split('::').last.downcase.to_sym
          end

          def initialize(name, context, &block)
            @context = context
            @name = name
            @root = context.root
            @dsl = Dsl.new(self)
            @extensions = ExtensionManager.new(self)
            @data = Data.new

            extensions.use(Extensions::Use)
            extensions.use(Extensions::Lib)
            extensions.use(Extensions::Env)
            extensions.use(Extensions::Notify)
            extensions.use(Extensions::Steps)
            extensions.use(Extensions::Plugins)

            instance_eval(&block) if block_given?
          end

          def to_h
            # Merge envs from main pipeline, since ruby does not have `reverse_merge` and
            # `data` does not allow keys override, we have to reset the data hash per key.
            context.data.env.merge(data.env).each do |key, value|
              data.env[key] = value
            end
            data.to_definition
          end

          def method_missing(method_name, *args, **kwargs, &_block)
            dsl.public_send(method_name, *args, **kwargs, &_block)
          end

          def pipeline_yml
            @pipeline_yml ||= "tmp/buildkite-builder/#{SecureRandom.urlsafe_base64}.yml"
          end
        end

        def prepare
          context.data.pipelines = PipelineCollection.new(context.artifacts)
        end

        dsl do
          def pipeline(name, &block)
            raise "Subpipeline must have a name" if name.empty?
            raise "Subpipeline does not allow nested in another Subpipeline" if context.is_a?(Buildkite::Builder::Extensions::SubPipelines::Pipeline)

            sub_pipeline = Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(name, context, &block)
            context.data.pipelines.add(sub_pipeline)

            trigger_step = context.data.steps.push(Pipelines::Steps::Trigger.new).last
            trigger_step.trigger(name)

            build_options = {
              message: '${BUILDKITE_MESSAGE}',
              commit: '${BUILDKITE_COMMIT}',
              branch: '${BUILDKITE_BRANCH}',
              env: {
                BUILDKITE_PULL_REQUEST: '${BUILDKITE_PULL_REQUEST}',
                BUILDKITE_PULL_REQUEST_BASE_BRANCH: '${BUILDKITE_PULL_REQUEST_BASE_BRANCH}',
                BUILDKITE_PULL_REQUEST_REPO: '${BUILDKITE_PULL_REQUEST_REPO}',
                BKB_SUBPIPELINE_FILE: sub_pipeline.pipeline_yml
              }
            }
            build_options.merge!(sub_pipeline.build) if sub_pipeline.build

            trigger_step.build(build_options)
            trigger_step.key(sub_pipeline.key || "subpipeline_#{name}_#{context.data.pipelines.count}")
            trigger_step.label(sub_pipeline.label || name.capitalize)
            trigger_step.async(sub_pipeline.async || false)
            trigger_step.branches(sub_pipeline.branches) if sub_pipeline.branches
            trigger_step.condition(sub_pipeline.condition) if sub_pipeline.condition
            trigger_step.depends_on(*sub_pipeline.get('depends_on')) if sub_pipeline.get('depends_on')
            trigger_step.allow_dependency_failure(sub_pipeline.allow_dependency_failure || false)
            trigger_step.skip(sub_pipeline.skip || false)
          end
        end
      end
    end
  end
end
