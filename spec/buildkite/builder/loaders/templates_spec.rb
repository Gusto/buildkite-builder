# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Loaders::Templates do
  describe '.load' do
    let(:pipeline) { 'dummy' }

    context 'when templates path exists' do
      before do
        setup_project(:basic)
      end

      it 'loads the templates' do
        assets = described_class.load(pipeline)
        template = assets['basic']

        expect(assets.size).to eq(1)
        expect(template).to be_a(Buildkite::Builder::Definition::Template)

        step = Buildkite::Pipelines::Steps::Command.new(pipeline, template)
        expect(step.label).to eq('Basic step')
        expect(step.command).to eq(['true'])
      end
    end

    context 'when templates path does not exist' do
      before do
        setup_project(:invalid_pipeline)
      end

      it 'returns an empty hash' do
        expect(described_class.load(pipeline)).to be_empty
      end
    end
  end
end
