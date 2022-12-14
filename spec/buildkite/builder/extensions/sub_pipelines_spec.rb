# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::SubPipelines do
  before do
    setup_project(fixture_project)
  end

  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }

  describe '#new' do
    let(:root) { Buildkite::Builder.root }
    let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new, root: root) }

    it 'sets pipelines' do
      described_class.new(context)
      expect(context.data.pipelines).to be_a(Buildkite::Builder::PipelineCollection)
    end
  end

  context 'dsl methods' do
    describe 'pipeline' do
      it 'adds pipeline to pipelines in collection' do
        pipeline.dsl.pipeline(:foo)
        sub_pipeline = pipeline.data.pipelines.pipelines.first

        expect(sub_pipeline).to be_a(Buildkite::Builder::Extensions::SubPipelines::Pipeline)
        expect(sub_pipeline.name).to eq(:foo)
      end

      context 'when no name' do
        it 'raises error' do
          expect {
            pipeline.dsl.pipeline('')
          }.to raise_error(RuntimeError, 'Subpipeline must have a name')
        end
      end

      context 'when nested pipeline' do
        it 'raises error' do
          pipeline_context = Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, pipeline)
          new_dsl = Buildkite::Builder::Dsl.new(Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, pipeline_context)).extend(described_class)

          expect {
            new_dsl.pipeline(:bar)
          }.to raise_error(RuntimeError, 'Subpipeline does not allow nested in another Subpipeline')
        end
      end

      it 'uses pre-generated trigger step' do
        pipeline.dsl.pipeline(:foo)
        sub_pipeline = pipeline.data.pipelines.pipelines.first
        step = pipeline.data.steps.steps.last

        expect(step).to be_a(Buildkite::Pipelines::Steps::Trigger)
        expect(step.key).to eq('subpipeline_foo_1')
        expect(step.trigger).to eq(sub_pipeline.name)
        expect(step.build).to eq(
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

      context 'with options' do
        it 'uses pre-generated trigger step with options' do
          pipeline.dsl.pipeline(:foo) do
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
          sub_pipeline = pipeline.data.pipelines.pipelines.first
          step = pipeline.data.steps.steps.last

          expect(step).to be_a(Buildkite::Pipelines::Steps::Trigger)
          expect(step.key).to eq('bar')
          expect(step.label).to eq(':rocket: Foo')
          expect(step.trigger).to eq(sub_pipeline.name)
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
              BKB_SUBPIPELINE_FILE: sub_pipeline.pipeline_yml
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
