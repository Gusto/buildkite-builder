# frozen_string_literal: true

RSpec.describe Buildkite::Builder do
  shared_examples 'definition method' do |definition_method, definition_class|
    context 'when a block is given' do
      it 'returns the definition' do
        result = described_class.public_send(definition_method) {}

        expect(result).to be_a(definition_class)
      end
    end

    context 'when a block is not given' do
      it 'returns nil' do
        result = described_class.public_send(definition_method)

        expect(result).to be_nil
      end
    end
  end

  describe '.template' do
    include_examples 'definition method', :template, Buildkite::Builder::Definition::Template
  end

  describe '.pipeline' do
    include_examples 'definition method', :pipeline, Buildkite::Builder::Definition::Pipeline
  end
end
