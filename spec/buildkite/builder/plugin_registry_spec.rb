# frozen_string_literal: true

RSpec.describe Buildkite::Builder::PluginRegistry do
  let(:registry) { described_class.new }

  describe '#add' do
    it 'adds to plugins' do
      registry.add('foo', 'org/some_repo', 'v0.0.1')

      expect(registry.fetch('foo')).to eq(['org/some_repo', 'v0.0.1'])
    end

    context 'when already added' do
      it 'raises error' do
        registry.add('foo', 'org/some_repo', 'v0.0.1')

        expect {
          registry.add('foo', 'org/some_repo', 'v0.0.2')
      }.to raise_error(ArgumentError, "Plugin already defined: foo")
      end
    end
  end
end
