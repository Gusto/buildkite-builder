require 'securerandom'

module Buildkite
  module Builder
    module Extensions
      class SubPipelines < Extension
        class Pipeline
          include Buildkite::Pipelines::Attributes

          attr_reader :data, :name, :dsl

          attribute :depends_on, append: true
          attribute :key

          def self.to_sym
            name.split('::').last.downcase.to_sym
          end

          def initialize(name, context, &block)
            @name = name
            @data = Data.new
            @data.steps = StepCollection.new(
              context.data.steps.templates,
              context.data.steps.plugins
            )
            @data.notify = []
            @data.env = context.data.env.dup

            # Use `clone` to copy over dsl's extended extensions
            @dsl = context.dsl.clone
            @dsl.context.data = @data

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
          def pipeline(name, **options, &block)
            raise "Subpipeline must have a name" if name.empty?
            raise "Subpipeline does not allow nested in another Subpipeline" if context.is_a?(Buildkite::Builder::Extensions::SubPipelines::Pipeline)

            sub_pipeline = Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(name, context, &block)
            context.data.pipelines.add(sub_pipeline)

            options = options.slice(:key, :label, :async, :branches, :condition, :depends_on, :allow_dependency_failure, :skip, :emoji)
            options[:key] ||= "subpipeline_#{name}_#{context.data.pipelines.count}"
            options[:label] ||= name.capitalize

            if options[:emoji]
              emoji = Array(options.delete(:emoji)).map { |name| ":#{name}:" }.join
              options[:label] = [emoji, options[:label]].compact.join(' ')
            end

            context.data.steps.add(Pipelines::Steps::Trigger, **options) do |context|
              key context[:key]
              label context[:label]
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
              async context[:async] || false
              branches context[:branches] if context[:branches]
              condition context[:condition] if context[:condition]
              depends_on *context[:depends_on] if context[:depends_on]
              allow_dependency_failure context[:allow_dependency_failure] || false
              skip context[:skip] || false
            end
          end
        end
      end
    end
  end
end
