# frozen_string_literal: true

RSpec.describe Buildkite::Builder::PluginManager do
  let(:manager) { described_class.new }

  describe '#add' do
    it 'adds to plugins' do
      manager.add('foo', 'org/some_repo#v0.0.1')

      expect(manager.fetch('foo')).to eq('org/some_repo#v0.0.1')
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
end
