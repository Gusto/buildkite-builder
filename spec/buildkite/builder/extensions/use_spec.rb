# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Use do
  let(:context) { double }
  let(:dsl) do
    Buildkite::Builder::Dsl.new(context).extend(described_class)
  end

  it 'delegate use on context' do
    block = Proc.new {}
    expect(context).to receive(:use).with('FOO', bar: :baz, &block)

    dsl.use('FOO', bar: :baz, &block)
  end
end
