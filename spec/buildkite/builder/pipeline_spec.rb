# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Pipeline do
  before do
    setup_project(fixture_project)
  end
  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }

  describe '.build' do
    it 'initializes and builds the pipeline' do
      pipeline = described_class.build(fixture_path)

      expect(pipeline).to be_a(Buildkite::Builder::Pipeline)
    end
  end

  describe '.new' do
    it 'does not preemptively build the pipeline' do
      pipeline = described_class.new(fixture_path)

      expect(pipeline.built?).to eq(false)
    end

    it 'sets attributes' do
      logger = Logger.new(STDOUT)
      pipeline = described_class.new(fixture_path, logger: logger)

      expect(pipeline.root).to eq(fixture_path)
      expect(pipeline.logger).to eq(logger)
    end
  end

  describe '#build' do
    let(:fixture_project) { :basic_with_shared_and_pipeline_processors }
    let(:pipeline) { described_class.new(fixture_path) }

    it 'is idempotent' do
      pipeline_instance = pipeline.build

      expect(pipeline.build).to equal(pipeline_instance)
    end

    it 'loads manifests' do
      pipeline.build
      manifests = Buildkite::Builder::Manifest.manifests

      expect(manifests.size).to eq(1)
      expect(manifests).to have_key('basic')
      expect(manifests['basic']).to be_a(Buildkite::Builder::Manifest)
    end

    it 'loads templates' do
      pipeline_instance = pipeline.build
      templates = pipeline_instance.templates

      expect(templates.size).to eq(1)
      expect(templates).to have_key('basic')
      expect(templates['basic']).to be_a(Buildkite::Builder::Definition::Template)
    end

    it 'loads processors' do
      processors = pipeline.build.processors

      expect(processors.size).to eq(2)
    end

    it 'loads the pipeline' do
      pipeline_data = YAML.load(pipeline.build.to_yaml)

      expect(pipeline_data.dig('steps', 0, 'label')).to eq('Basic step')
    end

    it 'runs the processors' do
      steps = pipeline.build.steps
      steps_label_and_commands = steps.map { |step| [step.label, step.command] }

      expect(steps_label_and_commands).to eq([
        ['Basic step', ['true']],
        ['Appended By Processors::PipelineSpecificProcessor', ['echo 1']],
        ['Appended By Processors::SharedProcessor', ['echo 1']],
      ])
    end

    it 'returns the pipeline' do
      expect(pipeline.build).to be_a(Buildkite::Builder::Pipeline)
    end

    context 'with an invalid pipeline' do
      let(:fixture_project) { :invalid_pipeline }

      it 'raises an error' do
        expect {
          pipeline.build
        }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Pipeline\)/)
      end
    end

    context 'with an invalid step' do
      let(:fixture_project) { :invalid_step }

      it 'raises an error' do
        expect {
          pipeline.build
        }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Template\)/)
      end
    end
  end

  describe '#upload' do
    let(:pipeline) { described_class.new(fixture_path) }

    it 'sets pipeline and uploads to Buildkite' do
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

      expect(pipeline.built?).to eq(false)

      pipeline.upload

      expect(File.exist?(artifact_path)).to eq(false)
      expect(File.exist?(pipeline_path)).to eq(false)
      expect(artifact_contents).to eq(pipeline_contents)
      expect(pipeline_contents).to eq(<<~YAML)
        ---
        steps:
        - label: Basic step
          command:
          - 'true'
      YAML
    end

    context 'when has custom artifacts to upload' do
      let(:bar) do
        { bar: :baz }.to_json
      end

      let(:dummy_file) { File.open(Pathname.new('spec/fixtures/dummy_artifact')) }

      before do
        # Existing file
        pipeline.artifacts << dummy_file.path

        # Tempfile on the fly
        tempfile = Tempfile.new('bar.json')
        tempfile.sync = true
        tempfile.write(bar)
        pipeline.artifacts << tempfile.path
      end

      it 'uploads custom artifacts' do
        artifact_paths = []
        artifact_contents = {}

        # 2 custom files, 1 pipeline.yml
        expect(Buildkite::Pipelines::Command).to receive(:artifact!).exactly(3).times do |subcommand, path|
          expect(subcommand).to eq(:upload)
          artifact_contents[path] = File.read(path)
        end

        expect(Buildkite::Pipelines::Command).to receive(:pipeline!).ordered do |subcommand, path|
          expect(subcommand).to eq(:upload)
          pipeline_path = path
          pipeline_contents = File.read(path)
        end

        pipeline.upload

        artifact_contents.each do |filename, content|
          if filename =~ /dummy_artifact/
            expect(content).to eq(dummy_file.read)
          elsif filename =~ /bar.json/
            expect(content).to eq(bar)
          elsif filename =~ /pipeline.yml/
            expect(content).to eq(<<~YAML)
              ---
              steps:
              - label: Basic step
                command:
                - 'true'
            YAML
          end
        end
      end
    end
  end

  context 'serialization' do
    let(:pipeline) { described_class.build(fixture_path) }

    before do
      payload
      pipeline.command { command('foo-command') }
      pipeline.trigger { trigger('foo-trigger') }
      pipeline.wait(continue_on_failure: true)
      pipeline.block { block('foo-block') }
      pipeline.input { input('foo-block') }
      pipeline.skip { skip('foo-block') }
    end

    let(:payload) do
      payload_hash = pipeline.to_h
      payload_hash['steps'] += [
        { 'command' => ['foo-command'] },
        { 'trigger' => 'foo-trigger' },
        { 'wait' => nil, 'continue_on_failure' => true },
        { 'block' => 'foo-block' },
        { 'input' => 'foo-block' },
        { 'skip' => 'foo-block', 'command' => nil },
      ]
      payload_hash
    end

    describe '#to_h' do
      context 'when env is specified' do
        before do
          pipeline.env(FOO: 'foo')
        end

        it 'includes the env key' do
          expect(pipeline.to_h).to eq(
            payload.merge(
              'env' => {
                'FOO' => 'foo',
              }
            )
          )
        end
      end

      it 'builds the pipeline hash' do
        expect(pipeline.to_h).to eq(payload)
      end
    end

    describe '#to_yaml' do
      it 'dumps the pipeline to yaml' do
        expect(pipeline.to_yaml).to eq(YAML.dump(pipeline.to_h))
      end
    end
  end
end
