# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Command do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :command
    end
  end

  let(:step) { step_klass.new }

  describe "#command" do
    it "sets what's passed in" do
      step.command(:foo)

      expect(step.get(:command)).to eq(:foo)
    end
  end
end
