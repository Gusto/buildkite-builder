# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Plugins do
  let(:step_klass) do
    Class.new(Buildkite::Pipelines::Steps::Abstract) do
      attribute :plugins, append: true
    end
  end
  let(:pipeline) { Buildkite::Builder::Pipeline.new(setup_project_fixture(:simple)) }
  let(:step) { step_klass.new }

  describe '#plugin' do
    it 'sets plugins' do
      step.plugin(:foo, { key1: "value1" })
      step.plugin("bar#v1.2.3", { key2: "value2" })
      step.plugin(:baz)

      expect(step.plugins).to eq([
        { :foo => { key1: "value1" } },
        { 'bar#v1.2.3' => { key2: "value2" } },
        { :baz => {} },
      ])
    end
  end
end
