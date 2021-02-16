# frozen_string_literal: true

require 'fileutils'

RSpec.describe Buildkite::Builder::Loaders::Manifests do
  describe '.load' do
    context 'when manifests path exists' do
      let(:root) { fixture_pipeline_path_for(:basic, :dummy) }

      before do
        setup_project(:basic)
      end

      it 'loads the manifests' do
        project_root = fixture_path_for(:basic)
        project_root.join('basic').mkpath
        FileUtils.touch(project_root.join('basic/foo.txt'))

        assets = described_class.load(root)
        manifest = assets['basic']

        expect(assets.size).to eq(1)
        expect(manifest).to be_a(Buildkite::Builder::Manifest)
        expect(manifest.root).to eq(Buildkite::Builder.root)
        expect(manifest.files.size).to eq(1)
        expect(manifest.files.first).to eq(Pathname.new('basic/foo.txt'))
      end
    end

    context 'when manifests path does not exist' do
      let(:root) { fixture_pipeline_path_for(:invalid_step, :dummy) }

      before do
        setup_project(:invalid_step)
      end

      it 'returns an empty hash' do
        expect(described_class.load(root)).to be_empty
      end
    end
  end
end
