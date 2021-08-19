# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Loaders::Templates do
  describe '.load' do
    context 'when templates path exists' do
      let(:root) { fixture_pipeline_path_for(:basic, :dummy) }

      before do
        setup_project(:basic)
      end

      it 'loads the templates' do
        assets = described_class.load(root)
        template = assets['basic']

        expect(assets.size).to eq(1)
        expect(template).to be_a(Buildkite::Builder::Definition::Template)
        step_collection = Buildkite::Builder::StepCollection.new(
          Buildkite::Builder::TemplateRegistry.new(root),
          Buildkite::Builder::PluginRegistry.new
        )
        step = Buildkite::Pipelines::Steps::Command.new(step_collection, 'basic')
        expect(step.label).to eq('Basic step')
        expect(step.command).to eq(['true'])
      end
    end

    context 'when templates path does not exist' do
      let(:root) { fixture_pipeline_path_for(:invalid_pipeline, :dummy) }

      before do
        setup_project(:invalid_pipeline)
      end

      it 'returns an empty hash' do
        expect(described_class.load(root)).to be_empty
      end
    end
  end
end
