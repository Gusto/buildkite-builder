# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::TimeoutInMinutes do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :timeout_in_minutes
    end
  end

  let(:step) { step_klass.new }

  describe '#timeout' do
    it 'sets timeout_in_minutes' do
      expect {
        step.timeout(10)
      }.to change {
        step.get(:timeout_in_minutes)
      }.from(nil).to(10)
    end
  end
end
