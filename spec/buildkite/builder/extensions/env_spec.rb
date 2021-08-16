# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Env do
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new) }
  let(:dsl) do
    Buildkite::Builder::Dsl.new(context).extend(described_class)
  end

  # Sets data
  before { described_class.new(context) }

  it 'adds `env` as dsl method to context and sets env data' do
    expect {
      dsl.env(FOO: '1')
      dsl.env(BAR: '2')
    }.not_to raise_error

    expect(context.data.env).to eq('FOO' => '1', 'BAR' => '2' )
  end

  context 'when argument is not hash' do
    it 'raises' do
      expect {
        dsl.env('FOO')
      }.to raise_error(ArgumentError, 'value must be hash')
    end
  end
end
