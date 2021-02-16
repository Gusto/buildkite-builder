# frozen_string_literal: true

require 'yaml'

RSpec.describe Buildkite::Pipelines::Pipeline do
  before do
    pipeline.templates[step_name] = Buildkite::Builder.template {}
  end

  let(:pipeline) { described_class.new }
  let(:step_name) { 'dummy' }
  let(:defined_steps) { {} }

  shared_examples 'a step type' do |type|
    it 'adds and returns the step' do
      step = pipeline.public_send(type.to_sym)
      expect(pipeline.steps.last).to eq(step)
      expect(pipeline.steps.size).to eq(1)

      step = pipeline.public_send(type.to_sym)
      expect(pipeline.steps.last).to eq(step)
      expect(pipeline.steps.size).to eq(2)
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

  context 'serialization' do
    before do
      pipeline.command { command('foo-command') }
      pipeline.trigger { trigger('foo-trigger') }
      pipeline.wait(continue_on_failure: true)
      pipeline.block { block('foo-block') }
      pipeline.input { input('foo-block') }
      pipeline.skip { skip('foo-block') }
    end

    describe '#to_h' do
      context 'when env is specified' do
        before do
          pipeline.env(FOO: 'foo')
        end

        it 'includes the env key' do
          expect(pipeline.to_h).to eq(
            'env' => {
              'FOO' => 'foo',
            },
            'steps' => [
              { 'command' => ['foo-command'] },
              { 'trigger' => 'foo-trigger' },
              { 'wait' => nil, 'continue_on_failure' => true },
              { 'block' => 'foo-block' },
              { 'input' => 'foo-block' },
              { 'skip' => 'foo-block', 'command' => nil },
            ]
          )
        end
      end

      it 'builds the pipeline hash' do
        expect(pipeline.to_h).to eq(
          'steps' => [
            { 'command' => ['foo-command'] },
            { 'trigger' => 'foo-trigger' },
            { 'wait' => nil, 'continue_on_failure' => true },
            { 'block' => 'foo-block' },
            { 'input' => 'foo-block' },
            { 'skip' => 'foo-block', 'command' => nil },
          ]
        )
      end
    end

    describe '#to_yaml' do
      it 'dumps the pipeline to yaml' do
        expect(pipeline.to_yaml).to eq(YAML.dump(pipeline.to_h))
      end
    end
  end
end
