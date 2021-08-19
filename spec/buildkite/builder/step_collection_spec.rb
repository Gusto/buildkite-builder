# frozen_string_literal: true

RSpec.describe Buildkite::Builder::StepCollection do
  let(:root) { Buildkite::Builder.root }
  let(:collection) { described_class.new(Buildkite::Builder::TemplateRegistry.new(root), Buildkite::Builder::PluginRegistry.new) }

  describe '#each' do
    # TODO: write specs
  end

  describe '#add' do
    it 'adds to steps' do
      step = collection.add(Buildkite::Pipelines::Steps::Command)

      expect(step).to be_a(Buildkite::Pipelines::Steps::Command)
      expect(collection.steps).to be_include(step)
    end
  end

  describe '#push' do
    it 'pushes to steps' do
      collection.push('Foo')

      expect(collection.steps).to be_include('Foo')
    end
  end

  describe '#to_definition' do
    it 'returns an array of hashes' do
      collection.add(Buildkite::Pipelines::Steps::Command) do
        command 'true'
      end

      collection.add(Buildkite::Pipelines::Steps::Command) do
        condition 'false'
      end

      expect(collection.to_definition).to eq(
        [
          { 'command' => ['true'] },
          { 'if' => 'false' },
        ]
      )
    end
  end
end
