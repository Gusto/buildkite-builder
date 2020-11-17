# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Rainbow do
  it 'is only available as a refinement' do
    expect {
      'foo'.green
    }.to raise_error(NoMethodError)
  end

  context 'when used' do
    using Buildkite::Builder::Rainbow

    it 'adds color methods to String' do
      expect('foo'.green).to eq("\e[32mfoo\e[0m")
    end
  end
end
