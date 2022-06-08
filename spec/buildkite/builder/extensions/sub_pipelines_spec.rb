# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::SubPipelines do
  let(:root) { Buildkite::Builder.root }
  let(:steps) { Buildkite::Builder::StepCollection.new(Buildkite::Builder::TemplateManager.new(root), Buildkite::Builder::PluginManager.new) }
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new, root: root) }
  let(:dsl) do
    Buildkite::Builder::Dsl.new(context).extend(described_class)
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
      described_class.new(context)
      context.data.steps = steps
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
        let(:dsl) do
          context = Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, steps)
          Buildkite::Builder::Dsl.new(Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, steps)).extend(described_class)
        end

        it 'raises error' do
          expect {
            dsl.pipeline(:bar)
          }.to raise_error(RuntimeError, 'Subpipeline does not allow nested in another Subpipeline')
        end
      end

      context 'without template' do
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
      end

      context 'with template' do
        let(:template) { 'dummy' }
        let(:definition) do
          Buildkite::Builder.template do
            key 'dummy'
            trigger 'foo'
          end
        end

        before do
          allow(context.data.steps.templates).to receive(:find).and_call_original
          allow(context.data.steps.templates).to receive(:find).with(template).and_return(definition)
        end

        it 'builds trigger step by template' do
          dsl.pipeline(:foo, 'dummy')

          pipeline = context.data.pipelines.pipelines.first
          step = context.data.steps.steps.last

          expect(step).to be_a(Buildkite::Pipelines::Steps::Trigger)
          expect(step.key).to eq('dummy')
          expect(step.trigger).to eq('foo')
          expect(step.build[:env]).to eq(BKB_SUBPIPELINE_FILE: pipeline.pipeline_yml)
        end
      end
    end
  end
end
