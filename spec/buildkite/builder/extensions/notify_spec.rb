# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Notify do
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new) }
  let(:dsl) do
    Buildkite::Builder::Dsl.new(context).extend(described_class)
  end

  # Sets data
  before { described_class.new(context) }

  it 'adds `notify` as dsl method to context and sets notify data' do
    expect {
      dsl.notify email: 'foo@example.com'
      dsl.notify basecamp_campfire: 'https://3.basecamp.com/1234567/integrations/some_stuff/buckets/1234567/chats/1234567/lines'
    }.not_to raise_error

    expect(context.data.notify).to match_array([
      { 'email' => 'foo@example.com' },
      { 'basecamp_campfire' => 'https://3.basecamp.com/1234567/integrations/some_stuff/buckets/1234567/chats/1234567/lines' }
    ])
  end

  context 'when argument is not hash' do
    it 'raises' do
      expect {
        dsl.notify('FOO')
      }.to raise_error(ArgumentError, 'value must be hash')
    end
  end
end
