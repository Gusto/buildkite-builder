# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Steps::Abstract do
  let(:pipeline) { Buildkite::Builder::Pipeline.new(setup_project_fixture(:simple)) }
  let(:step) { step_class.new(pipeline) }
  let(:step_class) do
    stub_const(
      'Buildkite::Pipelines::Steps::Foo',
      Class.new(described_class) do
        attribute :foo_attribute
        attribute :bar_attribute
      end
    )
  end
  let(:template_name) { 'foo_template' }
  let(:template) do
    Buildkite::Builder.template do
      foo_attribute 'foo_value'
    end
  end

  before do
    allow(pipeline.data.steps.templates).to receive(:find).and_call_original
    allow(pipeline.data.steps.templates).to receive(:find).with(template_name).and_return(template)
  end

  describe '.new' do
    context 'when template definition is provided' do
      let(:step) { step_class.new(pipeline.data.steps, template_name) }

      it 'runs evaluates the template' do
        expect(step.foo_attribute).to eq('foo_value')
      end
    end

    context 'when args are provided' do
      let(:template) do
        Buildkite::Builder.template do |context|
          foo_attribute context[:arg1]
          bar_attribute context.args[:arg2]
        end
      end

      let(:step) { step_class.new(pipeline.data.steps, template_name, arg1: 'val1', arg2: 'val2') }

      it 'passes the context through' do
        expect(step.foo_attribute).to eq('val1')
        expect(step.bar_attribute).to eq('val2')
      end
    end

    context 'when data provided' do
      let(:template) do
        Buildkite::Builder.template do |context|
          context.data[:foo] = :bar
          context.data[:baz] = :boo
        end
      end

      let(:step) { step_class.new(pipeline.data.steps, template_name) }

      it 'passes the data through' do
        expect(step.data[:foo]).to eq(:bar)
        expect(step.data[:baz]).to eq(:boo)
      end
    end
  end

  describe '#template' do
    let(:step) { step_class.new(pipeline.data.steps, template_name) }

    it 'returns the template definition' do
      expect(step.template).to eq(template)
    end
  end
end
