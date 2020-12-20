# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::BlockedState do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :blocked_state
    end
  end

  let(:step) { step_klass.new }

  describe '#blocked_state' do
    context 'with a valid value' do
      let(:arg) { 'passed' }

      it 'returns true' do
        expect {
          step.blocked_state(arg)
        }.to change {
          step.get(:blocked_state)
        }.from(nil).to('passed')
      end
    end

    context 'with a valid value as symbol' do
      let(:arg) { :running }

      it 'returns true' do
        expect {
          step.blocked_state(arg)
        }.to change {
          step.get(:blocked_state)
        }.from(nil).to('running')
      end
    end

    context 'with an invalid value' do
      let(:arg) { 'some_invalid_value' }

      it 'raises error' do
        expect { step.blocked_state(arg) }.to raise_error(ArgumentError, /Cannot set blocked_state to/)
      end
    end

    context 'with wrong type' do
      let(:arg) { ['passed'] }

      it 'raises error' do
        expect { step.blocked_state(arg) }.to raise_error(ArgumentError, /Cannot set blocked_state to/)
      end
    end
  end
end
