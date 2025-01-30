# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Steps::Abstract do
  let(:step) { step_class.new }
  let(:step_class) do
    stub_const(
      'Buildkite::Pipelines::Steps::Foo',
      Class.new(described_class) do
        attribute :foo_attribute
        attribute :bar_attribute
      end
    )
  end

  describe '#process' do
    it 'evals the block' do
      block = proc do
        foo_attribute '1'
        bar_attribute '2'
      end

      step.process(block)

      expect(step.foo_attribute).to eq('1')
      expect(step.bar_attribute).to eq('2')
    end
  end
end
