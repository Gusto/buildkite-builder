# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Steps::Abstract do
  let(:pipeline) { Buildkite::Pipelines::Pipeline.new }
  let(:step) { step_class.new(pipeline) }
  let(:step_class) do
    stub_const(
      'Buildkite::Pipelines::Steps::Foo',
      Class.new(described_class) do
        attribute :foo_attribute
      end
    )
  end
  let(:template) do
    pipeline.template(:foo_template) do
      foo_attribute 'foo_value'
    end
  end

  describe '.new' do
    context 'when template definition is provided' do
      let(:step) { step_class.new(pipeline, template) }

      it 'runs evaluates the template' do
        expect(step.foo_attribute).to eq('foo_value')
      end
    end
  end

  describe '#template' do
    let(:step) { step_class.new(pipeline, template) }

    it 'returns the template definition' do
      expect(step.template).to eq(template)
    end
  end
end
