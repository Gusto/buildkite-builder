# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Loaders::Processors do
  describe '.load' do
    context 'when shared processors path exists' do
      let(:root) { fixture_pipeline_path_for(:basic_with_processors, :dummy) }

      before do
        setup_project(:basic_with_processors)
      end

      it 'loads the processors' do
        assets = described_class.load(root)

        expect(assets.size).to eq(1)
      end
    end

    context 'when shared processors path and pipeline processors path exists' do
      let(:root) { fixture_pipeline_path_for(:basic_with_shared_and_pipeline_processors, :dummy) }

      before do
        setup_project(:basic_with_shared_and_pipeline_processors)
      end

      it 'loads both processors' do
        assets = described_class.load(root)

        expect(assets.size).to eq(2)
      end
    end

    context 'when shared processors path does not exist' do
      let(:root) { fixture_pipeline_path_for(:basic, :dummy) }

      before do
        setup_project(:basic)
      end

      it 'returns an empty hash' do
        assets = described_class.load(root)

        expect(assets).to be_empty
      end
    end
  end
end
