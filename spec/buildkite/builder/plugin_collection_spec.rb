# frozen_string_literal: true

RSpec.describe Buildkite::Builder::PluginCollection do
  let(:manager) { Buildkite::Builder::PluginManager.new }
  let(:collection) { described_class.new(manager) }

  before { manager.add(:foo, 'foo-bar/test1#v0.0.1') }

  describe '#add' do
    context 'when resource is a symbol' do
      it 'adds plugin from manager' do
        plugin = collection.add(:foo, foo: 'bar')

        expect(plugin).to be_a(Buildkite::Builder::Plugin)
        expect(plugin.source).to eq('foo-bar/test1')
        expect(plugin.version).to eq('v0.0.1')
        expect(plugin.attributes).to eq(foo: 'bar')
      end

      context 'when source does not exist' do
        it 'raises error' do
          expect {
            collection.add(:bar, foo: 'bar')
          }.to raise_error("Plugin `bar` does not exist")
        end
      end
    end

    context 'when resource is a string' do
      it 'adds plugin' do
        plugin = collection.add('foo-bar/test2#v0.0.1', option1: 'one')

        expect(plugin).to be_a(Buildkite::Builder::Plugin)
        expect(plugin.source).to eq('foo-bar/test2')
        expect(plugin.version).to eq('v0.0.1')
        expect(plugin.attributes).to eq(option1: 'one')
      end
    end

    context 'when resource is a plugin' do
      it 'adds plugin' do
        plugin = collection.add(Buildkite::Builder::Plugin.new('foo-bar/test2#v0.0.1', option2: 'two'))

        expect(plugin).to be_a(Buildkite::Builder::Plugin)
        expect(plugin.source).to eq('foo-bar/test2')
        expect(plugin.version).to eq('v0.0.1')
        expect(plugin.attributes).to eq(option2: 'two')
      end
    end
  end

  describe '#find' do
    before do
      collection.add('foo-bar/test1#v0.0.1', option: 'one')
      collection.add('foo-bar/test1#v0.0.2', option: 'foo')
      collection.add('foo-boo/test1#v0.1.1', option: 'two', some: 'thing')
      collection.add('test-lib#v1.0.1', option: 'three')
    end

    context 'when source is a string' do
      it 'finds matched plugins from collection' do
        expect(collection.find('foo-bar/test1')).to contain_exactly(
          an_object_having_attributes(source: 'foo-bar/test1', version: 'v0.0.1', attributes: { option: 'one' }),
          an_object_having_attributes(source: 'foo-bar/test1', version: 'v0.0.2', attributes: { option: 'foo' }),
        )

        expect(collection.find('foo-boo/test1')).to contain_exactly(
          an_object_having_attributes(source: 'foo-boo/test1', version: 'v0.1.1', attributes: { option: 'two', some: 'thing' }),
        )

        expect(collection.find('test-lib')).to contain_exactly(
          an_object_having_attributes(source: 'test-lib', version: 'v1.0.1', attributes: { option: 'three' }),
        )
      end

      context 'when not found' do
        it 'returns empty array' do
          expect(collection.find('foo-bar/test2')).to be_empty
        end
      end
    end

    context 'when source is a Plugin' do
      it 'finds matched plugins from collection' do
        expect(collection.find(Buildkite::Builder::Plugin.new('foo-bar/test1#v0.0.1'))).to contain_exactly(
          an_object_having_attributes(source: 'foo-bar/test1', version: 'v0.0.1', attributes: { option: 'one' }),
          an_object_having_attributes(source: 'foo-bar/test1', version: 'v0.0.2', attributes: { option: 'foo' }),
        )

        expect(collection.find(Buildkite::Builder::Plugin.new('foo-boo/test1#0.2.3'))).to contain_exactly(
          an_object_having_attributes(source: 'foo-boo/test1', version: 'v0.1.1', attributes: { option: 'two', some: 'thing' }),
        )

        expect(collection.find(Buildkite::Builder::Plugin.new('test-lib#v1.2.3'))).to contain_exactly(
          an_object_having_attributes(source: 'test-lib', version: 'v1.0.1', attributes: { option: 'three' }),
        )
      end

      context 'when not found' do
        it 'returns empty array' do
          expect(collection.find(Buildkite::Builder::Plugin.new('foo-bar/test2#v0.2.2'))).to be_empty
        end
      end
    end

    context 'when unknown source' do
      it 'raises error' do
        expect {
          collection.find(double(inspect: 'foo'))
      }.to raise_error(ArgumentError, 'Unknown source foo')
      end
    end
  end
end
