# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Retry do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :retry
    end
  end

  let(:step) { step_klass.new }

  describe '#automatically_retry' do
    context 'when retry was set' do
      it 'pushes to the value array' do
        step.retry(automatic: [{ exit_status: 1, limit: 5 }])

        step.automatically_retry(status: 254, limit: 1)

        expect(step.get(:retry)).to eq(
          automatic: [
            { exit_status: 1, limit: 5 },
            { exit_status: 254, limit: 1 },
          ]
        )
      end
    end

    context 'when retry was set to something else' do
      it 'disregards previous value and set automatic correctly' do
        step.retry(automatic: :foo)

        step.automatically_retry(status: 254, limit: 1)

        expect(step.get(:retry)).to eq(
          automatic: [
            { exit_status: 254, limit: 1 },
          ]
        )
      end
    end
  end
end
