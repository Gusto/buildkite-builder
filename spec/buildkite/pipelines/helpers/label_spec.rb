# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Label do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :label
    end
  end

  let(:step) { step_klass.new }

  describe '#label' do
    it 'supports emoji' do
      step.label('foo', emoji: :rspec)

      expect(step.get(:label)).to eq(':rspec: foo')
    end

    it 'supports multiple emojis' do
      step.label('foo', emoji: ['rspec', 'pipeline'])

      expect(step.get(:label)).to eq(':rspec::pipeline: foo')
    end

    it 'returns the value' do
      step.label('foo')

      expect(step.label).to eq('foo')
    end
  end
end
