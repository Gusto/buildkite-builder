# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Loaders::Extensions do
  describe '.load' do
    context 'when shared extensions path exists' do
      let(:root) { fixture_pipeline_path_for(:basic_with_extensions, :dummy) }

      before do
        setup_project(:basic_with_extensions)
      end

      it 'loads the extensions' do
        assets = described_class.load(root)

        expect(assets.size).to eq(1)
      end
    end

    context 'when shared extensions path and pipeline extensions path exists' do
      let(:root) { fixture_pipeline_path_for(:basic_with_shared_and_pipeline_extensions, :dummy) }

      before do
        setup_project(:basic_with_shared_and_pipeline_extensions)
      end

      it 'loads both extensions' do
        assets = described_class.load(root)

        expect(assets.size).to eq(2)
      end
    end

    context 'when shared extensions path does not exist' do
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
