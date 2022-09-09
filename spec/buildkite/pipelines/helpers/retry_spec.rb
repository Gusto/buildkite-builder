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
    context 'when retry was set' do
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
