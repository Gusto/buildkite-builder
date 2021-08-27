# frozen_string_literal: true

require 'pathname'
require 'fileutils'

RSpec.describe Buildkite::Builder::Manifest do
  describe '.resolve' do
    it 'converts patterns to array' do
      root = double
      patterns = 'foo'
      manifest = double
      value = double

      expect(described_class).to receive(:new).with(root, [patterns]).and_return(manifest)
      expect(manifest).to receive(:modified?).and_return(value)
      expect(described_class.resolve(root, patterns)).to eq(value)
    end

    it 'returns the value' do
      root = double
      patterns = ['foo']
      manifest = double
      value = double

      expect(described_class).to receive(:new).with(root, patterns).and_return(manifest)
      expect(manifest).to receive(:modified?).and_return(value)
      expect(described_class.resolve(root, patterns)).to eq(value)
    end
  end

  describe '.manifests' do
    let(:root) { Pathname.new('tmp/manifest_spec') }

    before do
      allow(Buildkite::Builder).to receive(:root).and_return(root)
    end

    it 'returns registered manifests' do
      manifest = described_class.new(Buildkite::Builder.root, [])
      described_class[:foo] = manifest
      expect(described_class.manifests['foo']).to eq(manifest)
    end
  end

  describe '.[]' do
    let(:root) { Pathname.new('tmp/manifest_spec') }

    before do
      allow(Buildkite::Builder).to receive(:root).and_return(root)
    end

    it 'returns the manifest' do
      manifest = described_class.new(Buildkite::Builder.root, [])
      described_class['foo'] = manifest
      expect(described_class[:foo]).to eq(manifest)
    end
  end

  describe '.[]=' do
    let(:root) { Pathname.new('tmp/manifest_spec') }

    before do
      allow(Buildkite::Builder).to receive(:root).and_return(root)
    end

    it 'registers the manifest' do
      manifest = described_class.new(Buildkite::Builder.root, [])
      described_class[:foo] = manifest
      expect(described_class[:foo]).to eq(manifest)
    end

    it 'raises an error when registered twice' do
      manifest = described_class.new(Buildkite::Builder.root, [])
      described_class[:foo] = manifest

      expect {
        described_class[:foo] = manifest
      }.to raise_error(ArgumentError, /already exists/)
    end
  end

  describe '#modified?' do
    let(:root) { Pathname.new('tmp/manifest_spec') }
    let(:patterns) { ['**/*'] }
    let(:manifest) { described_class.new(root.expand_path, patterns) }

    before do
      allow(Buildkite::Builder).to receive(:root).and_return(root)
    end

    context 'when manifest files modified' do
      before do
        resolver = instance_double(Buildkite::Builder::FileResolver)
        allow(Buildkite::Builder::FileResolver).to receive(:resolve).and_return(resolver)
        allow(resolver).to receive(:modified_files).and_return(Set.new([
          'foo/bar',
        ]))
      end

      it 'returns true' do
        expect(manifest).to be_modified
      end
    end

    context 'when manifest not files modified' do
      let(:patterns) { ['foo/other'] }
      before do
        resolver = instance_double(Buildkite::Builder::FileResolver)
        allow(Buildkite::Builder::FileResolver).to receive(:resolve).and_return(resolver)
        allow(resolver).to receive(:modified_files).and_return(Set.new([
          'foo/bar',
        ]))
      end

      it 'returns false' do
        expect(manifest).not_to be_modified
      end
    end
  end

  describe '#files' do
    let(:root) { Pathname.new('tmp/manifest_spec').expand_path }
    let(:patterns) { ['/foo', 'bar/*', '!bar/exclude'] }
    let(:manifest) { described_class.new(root.expand_path, patterns) }

    before do
      allow(Buildkite::Builder).to receive(:root).and_return(root)
    end

    around do |example|
      root.mkpath
      FileUtils.touch(root.join('foo'))
      root.join('bar').mkpath
      FileUtils.touch(root.join('bar/include'))
      FileUtils.touch(root.join('bar/exclude'))
      example.run
      root.rmtree
    end

    it 'returns only included files' do
      expect(manifest.files).to eq(Set.new([Pathname.new('bar/include'), Pathname.new('foo')]))
    end
  end

  describe '#digest' do
    let(:root) { Pathname.new('tmp/manifest_spec').expand_path }
    let(:patterns) { ['/foo', 'bar/*', '!bar/exclude'] }
    let(:manifest) { described_class.new(root.expand_path, patterns) }

    before do
      allow(Buildkite::Builder).to receive(:root).and_return(root)
    end

    around do |example|
      root.mkpath
      FileUtils.touch(root.join('foo'))
      root.join('bar').mkpath
      FileUtils.touch(root.join('bar/include'))
      FileUtils.touch(root.join('bar/exclude'))
      example.run
      root.rmtree
    end

    it 'returns only included files' do
      expect(manifest.digest).to eq('020eb29b524d7ba672d9d48bc72db455')
    end
  end
end
