# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Plugins do
  let(:step_klass) do
    Class.new(Buildkite::Pipelines::Steps::Abstract) do
      attribute :plugins, append: true
    end
  end

  let(:pipeline) { Buildkite::Builder::Pipeline.new(setup_project_fixture(:simple)) }

  let(:step) { step_klass.new(pipeline.data.steps, nil) }

  before do
    pipeline.dsl.plugin(:docker_compose, 'docker-compose#v3.7.0')
    pipeline.dsl.plugin(:artifacts, 'artifacts#v1.3.0')
    pipeline.dsl.plugin(:foobar, 'ssh://git@github.com/example/foobar-buildkite-plugin.git#0.2')
    pipeline.dsl.plugin(:monorepo_diff, 'chronotc/monorepo-diff#v1.1.1')
    pipeline.dsl.plugin(:ecr, 'ecr#v2.0.0')
  end

  describe '#plugin' do
    it 'sets plugin' do
      step.plugin(:docker_compose)
      step.plugin(:artifacts)
      step.plugin(:foobar)
      step.plugin(:monorepo_diff)
      step.plugin(:ecr)

      expect(step.plugins.to_definition).to eq([
        { 'docker-compose#v3.7.0' => nil },
        { 'artifacts#v1.3.0' => nil },
        { 'ssh://git@github.com/example/artifacts-buildkite-plugin.git#0.2' => nil },
        { 'chronotc/monorepo-diff#v1.1.1' => nil },
        { 'ecr#v2.0.0' => nil },
      ])
    end
  end
end
