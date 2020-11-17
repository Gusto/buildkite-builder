# frozen_string_literal: true

require 'fileutils'

RSpec.describe Buildkite::Builder::Loaders::Manifests do
  describe '.load' do
    let(:pipeline) { 'dummy' }

    context 'when manifests path exists' do
      before do
        setup_project(:basic)
      end

      it 'loads the manifests' do
        Buildkite::Builder.root.join('basic').mkpath
        FileUtils.touch(Buildkite::Builder.root.join('basic/foo.txt'))

        assets = described_class.load(pipeline)
        manifest = assets['basic']

        expect(assets.size).to eq(1)
        expect(manifest).to be_a(Buildkite::Builder::Manifest)
        expect(manifest.root).to eq(Buildkite::Builder.root)
        expect(manifest.files.size).to eq(1)
        expect(manifest.files.first).to eq(Pathname.new('basic/foo.txt'))
      end
    end

    context 'when manifests path does not exist' do
      before do
        setup_project(:invalid_step)
      end

      it 'returns an empty hash' do
        expect(described_class.load(pipeline)).to be_empty
      end
    end
  end
end
