# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Loaders::Abstract do
  let(:root) { fixture_pipeline_path_for(:basic, :dummy) }

  let(:foo_loader) do
    Class.new(Buildkite::Builder::Loaders::Abstract) do
      attr_reader :load_called

      def load
        @load_called = true
      end
    end
  end

  before do
    stub_const('Buildkite::Builder::Loaders::Foo', foo_loader)
  end

  describe '.load' do
    it 'returns the assets from the loader' do
      assets = double
      foo_loader_instance = instance_double(foo_loader, assets: assets)

      expect(foo_loader).to receive(:new).with(root).and_return(foo_loader_instance)
      expect(foo_loader.load(root)).to eq(assets)
    end
  end

  describe '.new' do
    it 'calls the subclass load method' do
      foo_loader_instance = foo_loader.new(root)

      expect(foo_loader_instance.load_called).to eq(true)
    end
  end

  describe '#load' do
    it 'raises NotImplementedError' do
      expect { described_class.new(nil).load }.to raise_error(NotImplementedError)
    end
  end

  describe '#assets' do
    context 'when there are assets' do
      let(:foo_loader) do
        Class.new(Buildkite::Builder::Loaders::Abstract) do
          def load
            add(:foo, 'foo')
            add(:pipeline, 'dummy')
          end
        end
      end

      it 'returns a hash of loaded assets' do
        assets = foo_loader.new(root).assets

        expect(assets.size).to eq(2)
        expect(assets['foo']).to eq('foo')
        expect(assets['pipeline']).to eq('dummy')
      end
    end

    context 'when there are no assets' do
      it 'returns an empty hash' do
        assets = foo_loader.new(root).assets

        expect(assets).to be_a(Hash)
        expect(assets).to be_empty
      end
    end
  end

  describe '#root' do
    it 'returns the pipeline' do
      foo_loader_instance = foo_loader.new(root)

      expect(foo_loader_instance.root).to eq(root)
    end
  end
end
