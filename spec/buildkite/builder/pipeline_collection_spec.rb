# frozen_string_literal: true

RSpec.describe Buildkite::Builder::PipelineCollection do
  before do
    setup_project(fixture_project)
  end

  let(:artifacts) { [] }
  let(:collection) { described_class.new(artifacts) }
  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }

  before do
    pipeline.dsl.env('FOO' => 'bar')
  end

  describe '#add' do
    let(:sub_pipeline) do
      Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, pipeline)
    end

    it 'adds pipeline to collection' do
      collection.add(sub_pipeline)

      expect(collection.pipelines).to eq([sub_pipeline])
    end

    context 'when not a pipeline' do
      it 'raises error' do
        expect {
          collection.add('foo')
        }.to raise_error("`foo` must be a Buildkite::Builder::Extensions::SubPipelines::Pipeline")
      end
    end
  end

  describe '#each' do
    before do
      collection.add(Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, pipeline))
      collection.add(Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:bar, pipeline))
    end

    it 'iterates through pipelines' do
      pipelines = []
      collection.each do |sub_pipeline|
        pipelines << sub_pipeline.name
      end

      expect(pipelines).to match_array([:foo, :bar])
    end
  end

  describe '#to_definition' do
    let(:pipeline_1) do
      Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, pipeline) do
        key 'p1'
        env(BAZ: 'foo')
        command do
          label 'Step 1'
          command 'true'
        end
        # With template
        command(:basic)
      end
    end

    let(:pipeline_2) do
      Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, pipeline) do
        env(BAZ: 'baz')
        command do
          label 'Pipeline 2'
          command 'true'
        end
      end
    end

    it 'creates a file for each pipeline and adds to artifacts' do
      expect {
        collection.add(pipeline_1)
        collection.add(pipeline_2)
        # Can add same pipeline multiple times
        collection.add(pipeline_2)
        collection.to_definition
      }.to change(artifacts, :count).by(3)

      pipeline_1_yaml = YAML.load_file(artifacts[0])
      pipeline_2_yaml = YAML.load_file(artifacts[1])
      expect(pipeline_1_yaml).to eq(
        'env' => {
          'FOO' => 'bar',
          'BAZ' => 'foo'
        },
        'steps' => [
          { 'label' => 'Step 1', 'command' => ['true'] },
          { 'label' => 'Basic step', 'command' => ['true'] }
        ]
      )
      expect(pipeline_2_yaml).to eq(
        'env' => {
          'FOO' => 'bar',
          'BAZ' => 'baz'
        },
        'steps' => [
          { 'label' => 'Pipeline 2', 'command' => ['true'] }
        ]
      )
      expect(pipeline_2_yaml).to eq(YAML.load_file(artifacts[2]))
    end
  end
end
