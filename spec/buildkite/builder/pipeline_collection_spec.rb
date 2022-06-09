# frozen_string_literal: true

RSpec.describe Buildkite::Builder::PipelineCollection do
  let(:artifacts) { [] }
  let(:collection) { described_class.new(artifacts) }
  let(:root) { Buildkite::Builder.root }
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new, root: root) }
  let(:steps) { Buildkite::Builder::StepCollection.new(Buildkite::Builder::TemplateManager.new(root), Buildkite::Builder::PluginManager.new) }
  let(:dsl) do
    new_dsl = Buildkite::Builder::Dsl.new(context)
    new_dsl.extend(Buildkite::Builder::Extensions::Steps)
    new_dsl.extend(Buildkite::Builder::Extensions::Env)
    context.data.steps = steps
    context.data.env = {}

    new_dsl
  end

  before { context.dsl = dsl }

  describe '#add' do
    let(:pipeline) do
      Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, context)
    end

    it 'adds pipeline to collection' do
      collection.add(pipeline)

      expect(collection.pipelines).to eq([pipeline])
    end

    context 'when not a pipeline' do
      it 'raises error' do
        expect {
          collection.add('foo')
        }.to raise_error("`foo` must be a Buildkite::Builder::Extensions::SubPipelines::Pipeline")
      end
    end
  end

  describe '#to_definition' do
    let(:definition) do
      Buildkite::Builder.template do
        label 'Template Step'
        key 'dummy'
        command 'false'
      end
    end

    let(:pipeline_1) do
      Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, context) do
        command do
          label 'Step 1'
          command 'true'
        end
        # With template
        command(:template_foo)
      end
    end

    let(:pipeline_2) do
      Buildkite::Builder::Extensions::SubPipelines::Pipeline.new(:foo, context) do
        command do
          label 'Pipeline 2'
          command 'true'
        end
      end
    end

    before do
      allow(steps.templates).to receive(:find).and_call_original
      allow(steps.templates).to receive(:find).with(:template_foo).and_return(definition)
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
        'steps' => [
          { 'label' => 'Step 1', 'command' => ['true'] },
          { 'label' => 'Template Step', 'key' => 'dummy', 'command' => ['false'] }
        ]
      )
      expect(pipeline_2_yaml).to eq(
        'steps' => [
          { 'label' => 'Pipeline 2', 'command' => ['true'] }
        ]
      )
      expect(pipeline_2_yaml).to eq(YAML.load_file(artifacts[2]))
    end
  end
end
