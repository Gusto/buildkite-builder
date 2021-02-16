# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::StepContext do
  let(:step) { instance_double(Buildkite::Pipelines::Steps::Command) }
  let(:args) do
      {
        arg1: 'val1',
        arg2: 'val2'
      }
  end

  describe '.new' do
    it 'sets attributes' do
      context = described_class.new(step, **args)

      expect(context.step).to eq(step)
      expect(context.args).to eq(args)
    end
  end

  describe '#pipeline' do
    it 'returns the pipeline' do
      pipeline = instance_double(Buildkite::Pipelines::Pipeline)
      allow(step).to receive(:pipeline).and_return(pipeline)
      context = described_class.new(step, **args)

      expect(context.pipeline).to eq(pipeline)
    end
  end

  describe '#step' do
    it 'returns the step' do
      context = described_class.new(step, **args)

      expect(context.step).to eq(step)
    end
  end

  describe '#args' do
    it 'returns the args' do
      context = described_class.new(step, **args)

      expect(context.args).to eq(args)
    end
  end

  describe '#[]' do
    it 'returns args' do
      context = described_class.new(step, **args)

      expect(context[:arg1]).to eq(args[:arg1])
      expect(context[:arg2]).to eq(args[:arg2])
    end
  end
end
