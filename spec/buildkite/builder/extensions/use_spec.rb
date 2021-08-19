# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Use do
  let(:context) { double }
  let(:dsl) do
    Buildkite::Builder::Dsl.new(context).extend(described_class)
  end

  it 'delegate use on context' do
    expect(context).to receive(:use).with('FOO', bar: :baz)

    dsl.use('FOO', bar: :baz)
  end
end
