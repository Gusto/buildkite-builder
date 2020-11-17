# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Runner do
  describe '.run' do
    before do
      stub_buildkite_env(pipeline_slug: pipeline_slug)
    end

    let(:pipeline_slug) { 'dummy' }

    it 'calls runner instance with prefilled arguments' do
      runner = instance_double(described_class)
      expect(runner).to receive(:run).once
      expect(described_class).to receive(:new).with(
        upload: true,
        pipeline: pipeline_slug
      ).and_return(runner)

      described_class.run
    end
  end

  describe '#pipeline_definition' do
    let(:pipeline_name) { 'dummy' }
    let(:options) { { pipeline: pipeline_name } }
    let(:runner) { described_class.new(**options) }

    context 'for a non-component pipeline' do
      it 'returns the pipeline definition' do
        setup_project(:basic)

        expect(runner.pipeline_definition).to be_a(Buildkite::Builder::Definition::Pipeline)
      end
    end
  end

  describe '#run' do
    before do
      setup_project(fixture_project)
    end

    let(:fixture_project) { :basic_with_shared_and_pipeline_processors }
    let(:pipeline_name) { 'dummy' }
    let(:options) { { pipeline: pipeline_name } }
    let(:runner) { described_class.new(**options) }

    context 'with an invalid pipeline' do
      let(:fixture_project) { :invalid_pipeline }

      it 'raises an errors' do
        expect {
          runner.run
        }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Pipeline\)/)
      end
    end

    context 'with an invalid step' do
      let(:fixture_project) { :invalid_step }

      it 'raises an errors' do
        expect {
          runner.run
        }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Template\)/)
      end
    end

    it 'loads manifests' do
      runner.run

      manifests = Buildkite::Builder::Manifest.manifests
      expect(manifests.size).to eq(1)
      expect(manifests).to have_key('basic')
      expect(manifests['basic']).to be_a(Buildkite::Builder::Manifest)
    end

    it 'loads steps' do
      pipeline = runner.run

      steps = pipeline.templates
      expect(steps.size).to eq(1)
      expect(steps).to have_key('basic')
      expect(steps['basic']).to be_a(Buildkite::Builder::Definition::Template)
    end

    it 'loads processors' do
      pipeline = runner.run

      processors = pipeline.processors
      expect(processors.size).to eq(2)
    end

    it 'returns the pipeline' do
      expect(runner.run).to be_a(Buildkite::Pipelines::Pipeline)
    end

    it 'applies the processors' do
      pipeline = runner.run

      steps = pipeline.steps
      steps_label_and_commands = steps.map { |step| [step.label, step.command] }
      expect(steps_label_and_commands).to eq([
        ['Basic step', ['true']],
        ['Appended By Processors::PipelineSpecificProcessor', ['echo 1']],
        ['Appended By Processors::SharedProcessor', ['echo 1']],
      ])
    end

    context 'when uploading' do
      let(:options) do
        {
          pipeline: pipeline_name,
          upload: true,
        }
      end

      it 'uploads to Buildkite' do
        artifact_path = nil
        pipeline_path = nil
        artifact_contents = nil
        pipeline_contents = nil

        expect(Buildkite::Pipelines::Command).to receive(:artifact!).ordered do |subcommand, path|
          expect(subcommand).to eq(:upload)
          artifact_path = path
          artifact_contents = File.read(path)
        end

        expect(Buildkite::Pipelines::Command).to receive(:pipeline!).ordered do |subcommand, path|
          expect(subcommand).to eq(:upload)
          pipeline_path = path
          pipeline_contents = File.read(path)
        end

        runner.run

        expect(File.exist?(artifact_path)).to eq(false)
        expect(File.exist?(pipeline_path)).to eq(false)
        expect(artifact_contents).to eq(pipeline_contents)
        expect(pipeline_contents).to eq(runner.pipeline.to_yaml)
      end
    end
  end

  describe '#log', skip_logging_stubs: true do
    let(:pipeline_name) { 'dummy' }
    let(:options) { { pipeline: pipeline_name, verbose: verbose } }
    let(:verbose) { false }
    let(:runner) { described_class.new(**options) }

    context 'when verbose' do
      context 'when option is explicitly set to true' do
        let(:verbose) { true }

        it 'returns a Logger' do
          expect(runner.log).to be_a(Logger)
        end

        it 'logs to stdout' do
          expect {
            runner.log.info('foo')
          }.to output("foo\n").to_stdout
        end
      end

      context 'when option is not set explicitly' do
        let(:options) { { pipeline: pipeline_name } }

        it 'returns a Logger' do
          expect(runner.log).to be_a(Logger)
        end

        it 'logs to stdout' do
          expect {
            runner.log.info('foo')
          }.to output("foo\n").to_stdout
        end
      end
    end

    context 'when not verbose' do
      it 'returns a Logger' do
        expect(runner.log).to be_a(Logger)
      end

      it 'does not logs to stdout' do
        expect {
          runner.log.info('foo')
        }.not_to output.to_stdout
      end
    end
  end
end
