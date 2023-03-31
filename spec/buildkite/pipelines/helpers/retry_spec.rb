# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Retry do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :retry
    end
  end

  let(:step) { step_klass.new }

  describe '#automatic_retry' do
    it 'sets the automatic retry value' do
      step.automatic_retry(true)

      expect(step.get(:retry)).to eq(automatic: true)
    end

    it 'overwrites the previous setting' do
      step.automatic_retry(true)
      step.automatic_retry(false)

      expect(step.get(:retry)).to eq(automatic: false)
    end

    it 'does not touch manual portion' do
      step.retry(manual: false)
      step.automatic_retry(false)

      expect(step.get(:retry)).to eq(
        automatic: false,
        manual: false
      )
    end
  end

  describe '#manual_retry' do
    it 'sets the manual retry value' do
      step.manual_retry(false)

      expect(step.get(:retry)).to eq(
        manual: {
          allowed: false
        }
      )
    end

    it 'overwrites the previous setting' do
      step.manual_retry(true)
      step.manual_retry(false, reason: 'Nope', permit_on_passed: true)

      expect(step.get(:retry)).to eq(
        manual: {
          allowed: false,
          reason: 'Nope',
          permit_on_passed: true
        }
      )
    end

    it 'does not touch automatic portion' do
      step.retry(automatic: [{ exit_status: 1, limit: 5 }])
      step.manual_retry(false, reason: 'Nope', permit_on_passed: true)

      expect(step.get(:retry)).to eq(
        automatic: [
          {
            exit_status: 1,
            limit: 5
          }
        ],
        manual: {
          allowed: false,
          reason: 'Nope',
          permit_on_passed: true
        }
      )
    end
  end

  describe '#automatic_retry_on' do
    context 'when no limit' do
      it 'raises' do
        expect {
          step.automatic_retry_on(exit_status: 254)
        }.to raise_error('limit must set for `automatic_retry_on`.')
      end
    end

    context 'when no exit_status and signal_reason' do
      it 'raises' do
        expect {
          step.automatic_retry_on(limit: 1)
        }.to raise_error('signal_reason or exit_status must set for `automatic_retry_on`.')
      end
    end

    context 'when retry was set' do
      context 'with exit_status' do
        it 'pushes to the value array' do
          step.retry(manual: false, automatic: [{ exit_status: 1, limit: 5 }])

          step.automatic_retry_on(exit_status: 254, limit: 1)

          expect(step.get(:retry)).to eq(
            manual: false,
            automatic: [
              { exit_status: 1, limit: 5 },
              { exit_status: 254, limit: 1 },
            ]
          )
        end

        it 'replaces same exit status' do
          step.automatic_retry_on(exit_status: 123, limit: 1)
          step.automatic_retry_on(exit_status: 123, limit: 2)

          expect(step.get(:retry)).to eq(
            automatic: [
              { exit_status: 123, limit: 2 },
            ]
          )
        end
      end

      context 'with signal_reason' do
        it 'pushes to the value array' do
          step.retry(manual: false, automatic: [{ signal_reason: 'none', limit: 5 }])

          step.automatic_retry_on(exit_status: 254, limit: 1)

          expect(step.get(:retry)).to eq(
            manual: false,
            automatic: [
              { signal_reason: 'none', limit: 5 },
              { exit_status: 254, limit: 1 },
            ]
          )
        end

        it 'replaces same signal_reason' do
          step.automatic_retry_on(signal_reason: '*', limit: 1)
          step.automatic_retry_on(signal_reason: '*', limit: 2)

          expect(step.get(:retry)).to eq(
            automatic: [
              { signal_reason: '*', limit: 2 },
            ]
          )
        end
      end

      context 'with both signal_reason and exit_status' do
        it 'pushes to the value array' do
          step.retry(manual: false, automatic: [{ exit_status: 1, signal_reason: 'none', limit: 5 }])

          step.automatic_retry_on(exit_status: 254, signal_reason: 'agent_stop', limit: 1)

          expect(step.get(:retry)).to eq(
            manual: false,
            automatic: [
              { exit_status: 1, signal_reason: 'none', limit: 5 },
              { exit_status: 254, signal_reason: 'agent_stop', limit: 1 },
            ]
          )
        end

        it 'replaces same signal_reason and same exit_status' do
          step.automatic_retry_on(signal_reason: '*', exit_status: 254, limit: 1)
          step.automatic_retry_on(signal_reason: '*', exit_status: 254, limit: 2)

          expect(step.get(:retry)).to eq(
            automatic: [
              { signal_reason: '*', exit_status: 254, limit: 2 },
            ]
          )
        end

        it 'does not replace when only one of the signal_reason or exit_status is different' do
          step.automatic_retry_on(signal_reason: '*', exit_status: 254, limit: 1)
          step.automatic_retry_on(signal_reason: '*', exit_status: 1, limit: 2)
          step.automatic_retry_on(signal_reason: 'cancel', exit_status: 254, limit: 1)

          expect(step.get(:retry)).to eq(
            automatic: [
              { signal_reason: '*', exit_status: 254, limit: 1 },
              { signal_reason: '*', exit_status: 1, limit: 2 },
              { signal_reason: 'cancel', exit_status: 254, limit: 1 },
            ]
          )
        end

        it 'replaces when only one of the signal_reason or exit_status provided' do
          step.automatic_retry_on(signal_reason: '*', exit_status: 254, limit: 1)
          step.automatic_retry_on(signal_reason: 'none', exit_status: 1, limit: 1)
          step.automatic_retry_on(signal_reason: '*', limit: 2)
          step.automatic_retry_on(exit_status: 1, limit: 1)

          expect(step.get(:retry)).to eq(
            automatic: [
              { signal_reason: '*', limit: 2 },
              { exit_status: 1, limit: 1 },
            ]
          )
        end
      end
    end

    context 'when retry was set to something else' do
      it 'disregards previous value and set automatic correctly' do
        step.retry(automatic: :foo)

        step.automatic_retry_on(exit_status: 254, limit: 1)

        expect(step.get(:retry)).to eq(
          automatic: [
            { exit_status: 254, limit: 1 },
          ]
        )
      end
    end
  end
end
