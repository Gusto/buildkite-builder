# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Data do
  describe '#new' do
    let(:data) { described_class.new }

    it 'behaves like structed hash' do
      data.foo = 1
      expect(data.foo).to eq(1)
    end

    it 'does not allow re-assignment' do
      data.foo = 1
      expect {
        data.foo = 2
      }.to raise_error(ArgumentError, "Data already contains key 'foo'")
    end

    context 'with source hash' do
      it 'sets to data hash' do
        data = described_class.new(foo: 'bar', bar: 'baz')

        expect(data.foo).to eq('bar')
        expect(data.bar).to eq('baz')
      end
    end
  end
end
