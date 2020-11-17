# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Plugins do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :plugins, append: true

      attr_reader :pipeline

      def initialize(pipeline)
        @pipeline = pipeline
      end
    end
  end

  let(:pipeline) { Buildkite::Pipelines::Pipeline.new }

  let(:step) { step_klass.new(pipeline) }

  before do
    pipeline.plugin(:code_cache, 'ssh://git@github.com/Gusto/code-cache-buildkite-plugin.git', '65610a')
    pipeline.plugin(:docker_compose, 'docker-compose', 'v3.7.0')
    pipeline.plugin(:artifacts, 'artifacts', 'v1.3.0')
    pipeline.plugin(:gusto_artifacts, 'ssh://git@github.com/Gusto/artifacts-buildkite-plugin.git', '0.2')
    pipeline.plugin(:monorepo_diff, 'chronotc/monorepo-diff', 'v1.1.1')
    pipeline.plugin(:ecr, 'ecr', 'v2.0.0')
  end

  describe '#plugin' do
    it 'sets plugin' do
      step.plugin(:code_cache)

      expect(step.get(:plugins)).to eq([{ 'ssh://git@github.com/Gusto/code-cache-buildkite-plugin.git#65610a' => nil }])

      step.plugin(:docker_compose)
      step.plugin(:artifacts)
      step.plugin(:gusto_artifacts)
      step.plugin(:monorepo_diff)
      step.plugin(:ecr)

      expect(step.get(:plugins)).to eq([
        { 'ssh://git@github.com/Gusto/code-cache-buildkite-plugin.git#65610a' => nil },
        { 'docker-compose#v3.7.0' => nil },
        { 'artifacts#v1.3.0' => nil },
        { 'ssh://git@github.com/Gusto/artifacts-buildkite-plugin.git#0.2' => nil },
        { 'chronotc/monorepo-diff#v1.1.1' => nil },
        { 'ecr#v2.0.0' => nil },
      ])
    end

    context 'when already used' do
      it 'raises error' do
        step.plugin(:code_cache)

        expect {
          step.plugin(:code_cache)
        }.to raise_error(ArgumentError, 'Plugin already used for command step: code_cache')
      end
    end
  end
end
