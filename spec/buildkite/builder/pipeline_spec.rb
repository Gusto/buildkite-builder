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

  context 'steps' do
    let(:pipeline) { described_class.build(fixture_path) }
    let(:step_name) { 'dummy' }
    let(:defined_steps) { {} }

    before do
      pipeline.templates[step_name] = Buildkite::Builder.template {}
    end

    shared_examples 'a step type' do |type|
      it 'adds and returns the step' do
        steps = pipeline.steps.size
        step = pipeline.public_send(type.to_sym)
        expect(pipeline.steps.last).to eq(step)
        expect(pipeline.steps.size).to eq(steps + 1)

        step = pipeline.public_send(type.to_sym)
        expect(pipeline.steps.last).to eq(step)
        expect(pipeline.steps.size).to eq(steps + 2)
      end
    end

    shared_examples 'a step type that uses named steps' do |type|
      it 'loads the step from the given name' do
        step = pipeline.public_send(type.to_sym, step_name) { condition('foobar') }

        expect(step).to be_a(type)
        expect(step.condition).to eq('foobar')
      end

      it 'allows adhoc declaration' do
        step = pipeline.public_send(type.to_sym, step_name)
        step.condition('foobar')

        expect(step).to be_a(type)
        expect(step.condition).to eq('foobar')
      end
    end

    describe '#block' do
      include_examples 'a step type', Buildkite::Pipelines::Steps::Block
      include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Block
    end

    describe '#command' do
      include_examples 'a step type', Buildkite::Pipelines::Steps::Command
      include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Command
    end

    describe '#block' do
      include_examples 'a step type', Buildkite::Pipelines::Steps::Block
      include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Block
    end

    describe '#trigger' do
      include_examples 'a step type', Buildkite::Pipelines::Steps::Trigger
      include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Trigger
    end

    describe '#wait' do
      include_examples 'a step type', Buildkite::Pipelines::Steps::Wait

      it 'sets the wait attribute' do
        step = pipeline.wait

        expect(step.has?(:wait)).to eq(true)
        expect(step.wait).to be_nil
      end

      it 'allows adhoc declaration' do
        step = pipeline.wait { condition('foobar') }

        expect(step).to be_a(Buildkite::Pipelines::Steps::Wait)
        expect(step.condition).to eq('foobar')
        expect(step.has?(:wait)).to eq(true)
        expect(step.wait).to be_nil
      end

      it 'allows passed in options' do
        step = pipeline.wait(continue_on_failure: true)

        expect(step.continue_on_failure).to eq(true)
      end
    end

    describe '#skip' do
      include_examples 'a step type', Buildkite::Pipelines::Steps::Skip

      it 'sets the command attribute' do
        step = pipeline.skip(step_name) do
          skip 'foo-skip'
          command 'invalid'
        end

        expect(step.skip).to eq('foo-skip')
        expect(step.has?(:command)).to eq(true)
        expect(step.command).to be_nil
      end

      it 'sets the skip attribute' do
        step = pipeline.skip(step_name) do
          label 'Foo'
        end
        expect(step.skip).to eq(true)

        step = pipeline.skip(step_name) do
          label 'Foo'
          skip ''
        end
        expect(step.skip).to eq(true)

        step = pipeline.skip(step_name) do
          label 'Foo'
          skip false
        end
        expect(step.skip).to eq(true)
      end
    end

    describe '#notify' do
      context 'when called without arguments' do
        it 'returns the notify array' do
          expect(pipeline.notify).to eq([])

          pipeline.notify(email: 'foo@example.com')
          expect(pipeline.notify).to eq([{ 'email' => 'foo@example.com' }])
        end
      end

      context 'when called with a hash' do
        it 'appends to notify' do
          pipeline.notify(email: 'foo1@example.com')
          expect(pipeline.notify).to eq([
            { 'email' => 'foo1@example.com' }
          ])

          pipeline.notify(email: 'foo2@example.com')
          expect(pipeline.notify).to eq([
            { 'email' => 'foo1@example.com' },
            { 'email' => 'foo2@example.com' }
          ])
        end
      end

      context 'when called with something invalid' do
        it 'raises an error' do
          expect {
            pipeline.notify('invalid')
          }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#env' do
      context 'when called without arguments' do
        it 'returns the env hash' do
          expect(pipeline.env).to eq({})

          pipeline.env(FOO: 'foo', BAR: 'bar')
          expect(pipeline.env).to eq({ 'FOO' => 'foo', 'BAR' => 'bar' })
        end
      end

      context 'when called with a hash' do
        it 'updates env' do
          pipeline.env(FOO: 'foo')
          expect(pipeline.env).to eq({ 'FOO' => 'foo' })

          pipeline.env(BAR: 'bar')
          expect(pipeline.env).to eq({ 'FOO' => 'foo', 'BAR' => 'bar' })
        end
      end

      context 'when called with something invalid' do
        it 'raises an error' do
          expect {
            pipeline.env('invalid')
          }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#plugin' do
      it 'stores in plugins' do
        pipeline.plugin(:foo, 'foo.com', 'v1.2.3')

        expect(pipeline.plugins['foo']).to eq(['foo.com', 'v1.2.3'])
      end

      context 'when already defined' do
        it 'raises error' do
          pipeline.plugin(:foo, 'foo.com', 'v1.2.3')

          expect {
            pipeline.plugin('foo', 'foo.com', 'v1.2.3')
          }.to raise_error(ArgumentError, 'Plugin already defined: foo')
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
