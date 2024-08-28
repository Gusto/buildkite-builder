# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Agents do
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new) }
  let(:dsl) do
    Buildkite::Builder::Dsl.new(context).extend(described_class)
  end

  # Sets data
  before { described_class.new(context) }

  it 'adds `agents` as dsl method to context and sets agents data' do
    expect {
      dsl.agents(queue: 'priority')
      dsl.agents(postgres: '*')
    }.not_to raise_error

    expect(context.data.agents).to eq('queue' => 'priority', 'postgres' => '*' )
  end

  context 'when argument is not hash' do
    it 'raises' do
      expect {
        dsl.agents('FOO')
      }.to raise_error(ArgumentError, 'value must be hash')
    end
  end
end
