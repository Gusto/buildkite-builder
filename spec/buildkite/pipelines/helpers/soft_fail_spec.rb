# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::SoftFail do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :soft_fail, append: true
    end
  end

  let(:step) { step_klass.new }

  describe '#soft_fail' do
    context 'with `true` as argument' do
      let(:arg) { true }

      it 'returns true' do
        expect {
          step.soft_fail(arg)
        }.to change {
          step.get(:soft_fail)
        }.from(nil).to(true)
      end

      context 'with soft_fail previously set to an array' do
        let(:arg) { [{ exit_status: 1 }, { exit_status: 2 }, { exit_status: 3 }] }

        it 'raises when trying to be set to `true`' do
          step.soft_fail(arg)
          expect(step.soft_fail).to eq(arg)
          expect { step.soft_fail(true) }.to raise_error(ArgumentError)
        end
      end
    end

    context 'with an array as argument' do
      let(:arg) { [{ exit_status: 1 }, { exit_status: 2 }, { exit_status: 3 }] }

      it 'returns an array of exit_statuses' do
        expect {
          step.soft_fail(arg)
        }.to change {
          step.get(:soft_fail)
        }.from(nil).to(arg)
      end
    end
  end

  describe '#soft_fail_on_status' do
    it 'adds to soft fails' do
      expect {
        step.soft_fail_on_status(1, 2, 3, 4, 5)
      }.to change {
        step.get(:soft_fail)
      }.from(nil).to([
        { exit_status: 1 },
        { exit_status: 2 },
        { exit_status: 3 },
        { exit_status: 4 },
        { exit_status: 5 },
      ])
    end
  end
end
