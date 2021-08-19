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
  end
end
