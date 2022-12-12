# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::SubPipelines do
  let(:root) { Buildkite::Builder.root }
  let(:steps) { Buildkite::Builder::StepCollection.new(Buildkite::Builder::TemplateManager.new(root)) }
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new, root: root) }
  let(:dsl) do
    new_dsl = Buildkite::Builder::Dsl.new(context).extend(described_class)
    context.data.steps = steps
    context.data.env = {}

    new_dsl
  end

  describe '#new' do
    it 'sets pipelines' do
      described_class.new(context)
      expect(context.data.pipelines).to be_a(Buildkite::Builder::PipelineCollection)
    end
  end

  context 'dsl methods' do
    # sets up step collection
    before do
      context.dsl = dsl
      described_class.new(context)
    end

    describe 'pipeline' do
      it 'adds pipeline to pipelines in collection' do
        dsl.pipeline(:foo)
        pipeline = context.data.pipelines.pipelines.first

        expect(pipeline).to be_a(Buildkite::Builder::Extensions::SubPipelines::Pipeline)
        expect(pipeline.name).to eq(:foo)
      end

      context 'when no name' do
        it 'raises error' do
          expect {
            dsl.pipeline('')
          }.to raise_error(RuntimeError, 'Subpipeline must have a name')
        end
      end

      context 'when nested pipeline' do
        it 'raises error' do
          pipeline_context = Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, context)
          new_dsl = Buildkite::Builder::Dsl.new(Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, pipeline_context)).extend(described_class)

          expect {
            new_dsl.pipeline(:bar)
          }.to raise_error(RuntimeError, 'Subpipeline does not allow nested in another Subpipeline')
        end
      end

      it 'uses pre-generated trigger step' do
        dsl.pipeline(:foo)
        pipeline = context.data.pipelines.pipelines.first
        step = context.data.steps.steps.last

        expect(step).to be_a(Buildkite::Pipelines::Steps::Trigger)
        expect(step.key).to eq('subpipeline_foo_1')
        expect(step.trigger).to eq(pipeline.name)
        expect(step.build).to eq(
          message: '${BUILDKITE_MESSAGE}',
          commit: '${BUILDKITE_COMMIT}',
          branch: '${BUILDKITE_BRANCH}',
          env: {
            BUILDKITE_PULL_REQUEST: '${BUILDKITE_PULL_REQUEST}',
            BUILDKITE_PULL_REQUEST_BASE_BRANCH: '${BUILDKITE_PULL_REQUEST_BASE_BRANCH}',
            BUILDKITE_PULL_REQUEST_REPO: '${BUILDKITE_PULL_REQUEST_REPO}',
            BKB_SUBPIPELINE_FILE: pipeline.pipeline_yml
          }
        )
      end

      context 'with options' do
        it 'uses pre-generated trigger step with options' do
          dsl.pipeline(:foo) do
            key 'bar'
            label 'Foo', emoji: 'rocket'
            depends_on :bundle, :assets
            async true
            condition 'a = b'
            build(
              meta_data: {
                some_meta_data: "true"
              }
            )
          end
          pipeline = context.data.pipelines.pipelines.first
          step = context.data.steps.steps.last

          expect(step).to be_a(Buildkite::Pipelines::Steps::Trigger)
          expect(step.key).to eq('bar')
          expect(step.label).to eq(':rocket: Foo')
          expect(step.trigger).to eq(pipeline.name)
          expect(step.get('depends_on')).to eq(%i(bundle assets))
          expect(step.async).to eq(true)
          expect(step.condition).to eq('a = b')
          expect(step.build).to eq(
            message: '${BUILDKITE_MESSAGE}',
            commit: '${BUILDKITE_COMMIT}',
            branch: '${BUILDKITE_BRANCH}',
            env: {
              BUILDKITE_PULL_REQUEST: '${BUILDKITE_PULL_REQUEST}',
              BUILDKITE_PULL_REQUEST_BASE_BRANCH: '${BUILDKITE_PULL_REQUEST_BASE_BRANCH}',
              BUILDKITE_PULL_REQUEST_REPO: '${BUILDKITE_PULL_REQUEST_REPO}',
              BKB_SUBPIPELINE_FILE: pipeline.pipeline_yml
            },
            meta_data: {
              some_meta_data: "true"
            }
          )
        end
      end
    end
  end
end
