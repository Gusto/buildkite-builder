# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Context do
  before do
    setup_project(fixture_project)
  end
  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }

  describe '.build' do
    it 'initializes and builds the pipeline' do
      context = described_class.build(fixture_path)

      expect(context).to be_a(Buildkite::Builder::Context)
      expect(context.pipeline).to be_a(Buildkite::Pipelines::Pipeline)
    end
  end

  describe '.new' do
    it 'does not preemptively build the pipeline' do
      context = described_class.new(fixture_path)

      expect(context.pipeline).to be_nil
    end

    it 'sets attributes' do
      logger = Logger.new(STDOUT)
      context = described_class.new(fixture_path, logger: logger)

      expect(context.root).to eq(fixture_path)
      expect(context.logger).to eq(logger)
    end
  end

  describe '#build' do
    let(:fixture_project) { :basic_with_shared_and_pipeline_processors }
    let(:context) { described_class.new(fixture_path) }

    it 'is idempotent' do
      pipeline = context.build

      expect(context.build).to equal(pipeline)
    end

    it 'loads manifests' do
      context.build
      manifests = Buildkite::Builder::Manifest.manifests

      expect(manifests.size).to eq(1)
      expect(manifests).to have_key('basic')
      expect(manifests['basic']).to be_a(Buildkite::Builder::Manifest)
    end

    it 'loads templates' do
      pipeline = context.build
      templates = pipeline.templates

      expect(templates.size).to eq(1)
      expect(templates).to have_key('basic')
      expect(templates['basic']).to be_a(Buildkite::Builder::Definition::Template)
    end

    it 'loads processors' do
      processors = context.build.processors

      expect(processors.size).to eq(2)
    end

    it 'loads the pipeline' do
      pipeline = YAML.load(context.build.to_yaml)

      expect(pipeline.dig('steps', 0, 'label')).to eq('Basic step')
    end

    it 'runs the processors' do
      steps = context.build.steps
      steps_label_and_commands = steps.map { |step| [step.label, step.command] }

      expect(steps_label_and_commands).to eq([
        ['Basic step', ['true']],
        ['Appended By Processors::PipelineSpecificProcessor', ['echo 1']],
        ['Appended By Processors::SharedProcessor', ['echo 1']],
      ])
    end

    it 'returns the pipeline' do
      expect(context.build).to be_a(Buildkite::Pipelines::Pipeline)
    end

    context 'with an invalid pipeline' do
      let(:fixture_project) { :invalid_pipeline }

      it 'raises an error' do
        expect {
          context.build
        }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Pipeline\)/)
      end
    end

    context 'with an invalid step' do
      let(:fixture_project) { :invalid_step }

      it 'raises an error' do
        expect {
          context.build
        }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Template\)/)
      end
    end
  end
end
