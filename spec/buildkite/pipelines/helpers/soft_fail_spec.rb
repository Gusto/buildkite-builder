# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::SoftFail do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :soft_fail, append: true
    end
  end

  let(:step) { step_klass.new }

  describe '#soft_fail_on_status' do
    it 'adds to soft falis' do
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
