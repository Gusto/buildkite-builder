# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Block do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :block
    end
  end

  let(:step) { step_klass.new }

  describe '#block' do
    it 'supports emoji' do
      step.block('foo', emoji: :rspec)

      expect(step.get(:block)).to eq(':rspec: foo')
    end

    it 'supports multiple emojis' do
      step.block('foo', emoji: ['rspec', 'pipeline'])

      expect(step.get(:block)).to eq(':rspec::pipeline: foo')
    end

    it 'returns the value' do
      step.block('foo')

      expect(step.block).to eq('foo')
    end
  end
end
