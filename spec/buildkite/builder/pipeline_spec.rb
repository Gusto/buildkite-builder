# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Pipeline do
  before do
    setup_project(fixture_project)
  end
  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }

  describe '.new' do
    let(:pipeline) { described_class.new(fixture_path) }

    it 'sets attributes' do
      logger = Logger.new(STDOUT)
      pipeline = described_class.new(fixture_path, logger: logger)

      expect(pipeline.root).to eq(fixture_path)
      expect(pipeline.logger).to eq(logger)
    end

    it 'loads the pipeline' do
      pipeline_data = YAML.load(pipeline.to_yaml)

      expect(pipeline_data.dig('steps', 0, 'label')).to eq('Basic step')
    end

    it 'loads extensions' do
      expect(Buildkite::Builder::Loaders::Extensions).to receive(:load).with(fixture_path)

      pipeline
    end
  end

  describe '#upload' do
    before do
      stub_buildkite_env(job_id: '25cd9b9a-9ce3-4a92-99fb-6cab9f755dab', step_id: '0188f568-dc68-42d0-9bf7-40a48ee2c0c0')
    end

    let(:pipeline) { described_class.new(fixture_path) }

    context 'when there are no steps' do
      let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :empty) }

      it 'does not upload the pipeline' do
        expect(Buildkite::Pipelines::Command).to_not receive(:pipeline)
        expect(Buildkite::Pipelines::Command).to_not receive(:artifact!)
        expect(Buildkite::Pipelines::Command).to receive(:meta_data!).with(:set, anything, anything)

        pipeline.upload
      end

      context 'when only has groups but with no steps' do
        let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :empty_with_groups) }

      it 'does not upload the pipeline' do
        expect(Buildkite::Pipelines::Command).to_not receive(:pipeline)
        expect(Buildkite::Pipelines::Command).to_not receive(:artifact!)
        expect(Buildkite::Pipelines::Command).to receive(:meta_data!).with(:set, anything, anything)

        pipeline.upload
      end
      end
    end

    it 'sets pipeline and uploads to Buildkite' do
      pipeline_path = nil
      pipeline_contents = nil

      expect(Buildkite::Pipelines::Command).to_not receive(:artifact!)
      expect(Buildkite::Pipelines::Command).to receive(:meta_data!).with(:set, anything, anything)
      expect(Buildkite::Pipelines::Command).to receive(:pipeline).once do |subcommand, path|
        expect(subcommand).to eq(:upload)
        pipeline_path = path
        pipeline_contents = File.read(path)
        true
      end

      pipeline.upload

      expect(File.exist?(pipeline_path)).to eq(false)
      expect(pipeline_contents).to eq(<<~YAML)
        ---
        steps:
        - label: Basic step
          command:
          - 'true'
      YAML
    end

    it 'uploads the pipeline as an artifact on failure' do
      expect(Buildkite::Pipelines::Command).to receive(:pipeline).once.ordered.and_return(false)
      expect(Buildkite::Pipelines::Command).to receive(:artifact!).ordered.once do |subcommand, path|
        expect(subcommand).to eq(:upload)
        expect(File.read(path)).to eq(<<~YAML)
          ---
          steps:
          - label: Basic step
            command:
            - 'true'
        YAML
      end

      expect {
        pipeline.upload
      }.to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 1)))
    end

    context 'when there are custom artifacts to upload' do
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

        expect(Buildkite::Pipelines::Command).to receive(:artifact!).once do |subcommand, path|
          expect(subcommand).to eq(:upload)
          path.split(";").each do |artifact_path|
            artifact_contents[artifact_path] = File.read(artifact_path)
          end
        end

        expect(Buildkite::Pipelines::Command).to receive(:pipeline).once do |subcommand, path|
          expect(subcommand).to eq(:upload)
          pipeline_path = path
          pipeline_contents = File.read(path)
          true
        end

        expect(Buildkite::Pipelines::Command).to receive(:meta_data!).with(:set, anything, anything)

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
    describe '#to_h' do
      context 'when valid' do
        let(:pipeline) { described_class.new(fixture_path) }
        let!(:payload) do
          {
            'steps' => [
              { 'command' => ['foo-command'] },
              { 'trigger' => 'foo-trigger' },
              { 'wait' => nil, 'continue_on_failure' => true },
              { 'block' => 'foo-block' },
              { 'input' => 'foo-block' },
              { 'command' => ['true'], 'label' => 'Basic step' },
            ]
          }
        end

        before do
          pipeline.dsl.instance_eval do
            command { command('foo-command') }
            trigger { trigger('foo-trigger') }
            wait(continue_on_failure: true)
            block { block('foo-block') }
            input { input('foo-block') }
          end
        end

        context 'when env is specified' do
          before do
            pipeline.dsl.instance_eval do
              env(FOO: 'foo')
            end
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

      context 'with an invalid step' do
        let(:fixture_project) { :invalid_step }

        it 'raises an error' do
          expect {
            described_class.new(fixture_path).to_h
          }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Template\)/)
        end
      end

      context 'with an invalid pipeline' do
        let(:fixture_project) { :invalid_pipeline }

        it 'raises an error' do
          expect {
            described_class.new(fixture_path).to_h
          }.to raise_error(/must return a valid definition \(Buildkite::Builder::Definition::Pipeline\)/)
        end
      end

      context 'with sharedextensions' do
        let(:fixture_project) { :basic_with_shared_and_pipeline_extensions }
        let(:payload) do
          {
            'steps' => [
              { 'command' => ['true'], 'label' => 'Basic step' },
              { 'command' => ['echo 1'], 'label' => 'Appended By Extensions::PipelineSpecificExtension' },
              { 'command' => ['echo 1'], 'label' => 'Appended By Extensions::SharedExtension' }
            ]
          }
        end

        it 'builds the pipeline hash' do
          expect(described_class.new(fixture_path).to_h).to eq(payload)
        end
      end
    end

    describe '#to_yaml' do
      let(:pipeline) { described_class.new(fixture_path) }

      it 'dumps the pipeline to yaml' do
        expect(pipeline.to_yaml).to eq(YAML.dump(pipeline.to_h))
      end
    end
  end
end
