# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Skip do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :skip
    end
  end

  let(:step) { step_klass.new }

  describe '#skipped?' do
    it 'returns true for truthy value' do
      step.skip('skipped')
      expect(step).to be_skipped

      step.skip('true')
      expect(step).to be_skipped

      step.skip(true)
      expect(step).to be_skipped
    end

    it 'returns false for empty string' do
      step.skip('')
      expect(step).not_to be_skipped
    end

    it 'returns false for false boolean' do
      step.skip(false)
      expect(step).not_to be_skipped
    end
  end
end
