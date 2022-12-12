# frozen_string_literal: true

RSpec.describe Buildkite::Builder::PluginManager do
  let(:manager) { described_class.new }

  describe '#add' do
    it 'adds to plugins' do
      manager.add('foo', 'org/some_repo#v0.0.1')

      expect(manager.build('foo')).to eq({
        'org/some_repo#v0.0.1' => {}
      })
    end

    context 'when already added' do
      it 'raises error' do
        manager.add('foo', 'org/some_repo#v0.0.1')

        expect {
          manager.add('foo', 'org/some_repo#v0.0.2')
      }.to raise_error(ArgumentError, "Plugin already defined: foo")
      end
    end
  end

  describe '#build' do
    it 'builds on top of default attributes' do
      manager.add('foo', 'org/some_repo#v0.0.1', { default_key1: "value1" })

      expect(manager.build('foo', { default_key2: "value2" })).to eq({
        'org/some_repo#v0.0.1' => {
          default_key1: "value1",
          default_key2:"value2"
        }
      })
    end
  end
end
