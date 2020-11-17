# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Key do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :key
    end
  end

  let(:step) { step_klass.new }

  describe '#identifier' do
    it 'sets key' do
      step.identifier(:foo)

      expect(step.get(:key)).to eq(:foo)
    end
  end
end
