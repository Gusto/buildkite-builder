# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Command do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :command
    end
  end

  let(:step) { step_klass.new }

  describe '#command' do
    context 'when value is noop' do
      it 'sets true' do
        step.command(:noop)

        expect(step.get(:command)).to eq('true')
      end
    end

    context 'when other value' do
      it "sets what's passed in" do
        step.command(:foo)

        expect(step.get(:command)).to eq(:foo)
      end
    end
  end
end
