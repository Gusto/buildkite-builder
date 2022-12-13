# frozen_string_literal: true

RSpec.describe Buildkite::Builder::StepCollection do
  let(:root) { Buildkite::Builder.root }
  let(:collection) { described_class.new }

  describe '#each' do
    before do
      command_step = Buildkite::Pipelines::Steps::Command.new
      command_step.process(proc { key 'command' })
      block_step = Buildkite::Pipelines::Steps::Block.new
      block_step.process(proc { key 'block' })
      wait_step = Buildkite::Pipelines::Steps::Wait.new
      wait_step.process(proc { key 'wait' })

      collection.push(command_step)
      collection.push(block_step)
      collection.push(wait_step)
    end

    it 'iterates through steps' do
      keys = []
      collection.each do |step|
        keys << step.key
      end
      expect(keys).to match_array(['command', 'block', 'wait'])
    end

    context 'with types' do
      it 'iterates through steps with types' do
        collection.each(:command) do |step|
          expect(step.key).to eq('command')
        end

        collection.each(:block) do |step|
          expect(step.key).to eq('block')
        end

        collection.each(:wait) do |step|
          expect(step.key).to eq('wait')
        end

        keys = []
        collection.each(:command, :block) do |step|
          keys << step.key
        end
        expect(keys).to match_array(['command', 'block'])
      end
    end

    context 'with group' do
      before do
        setup_project(fixture_project)
      end

      let(:fixture_project) { :basic }
      let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
      let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }

      before do
        group = Buildkite::Builder::Group.new('group', pipeline) do
          command { key 'command_in_group' }
          block { key 'block_in_group' }
          wait { key 'wait_in_group' }
        end

        collection.push(group)
      end

      it "also iterates over group's steps" do
        command_keys, block_keys, wait_keys = [], [], []

        collection.each(:command) do |step|
          command_keys << step.key
        end
        expect(command_keys).to match_array(['command', 'command_in_group'])

        collection.each(:block) do |step|
          block_keys << step.key
        end
        expect(block_keys).to match_array(['block', 'block_in_group'])

        collection.each(:wait) do |step|
          wait_keys << step.key
        end
        expect(wait_keys).to match_array(['wait', 'wait_in_group'])
      end
    end
  end

  describe '#find' do
    let!(:command_step) do
      Buildkite::Pipelines::Steps::Command.new.tap do |step|
        step.process(proc { key 'command' })
        collection.push step
      end
    end
    let!(:block_step) do
      Buildkite::Pipelines::Steps::Block.new.tap do |step|
        step.process(proc { key 'block' })
        collection.push step
      end
    end
    let!(:command_step_without_key) do
      collection.push(Buildkite::Pipelines::Steps::Command.new)
    end

    it 'finds the step by key' do
      expect(collection.find(:command)).to eq(command_step)
      expect(collection.find(:block)).to eq(block_step)
    end

    it 'returns nil if step not found' do
      expect(collection.find(:foo)).to be_nil
    end
  end

  describe '#find!' do
    let!(:command_step) do
      Buildkite::Pipelines::Steps::Command.new.tap do |step|
        step.process(proc { key 'command' })
        collection.push step
      end
    end
    let!(:block_step) do
      Buildkite::Pipelines::Steps::Block.new.tap do |step|
        step.process(proc { key 'block' })
        collection.push step
      end
    end

    it 'finds the step by key' do
      expect(collection.find!(:command)).to eq(command_step)
      expect(collection.find!(:block)).to eq(block_step)
    end

    it 'raises error if key not found' do
      expect {
        collection.find!(:foo)
      }.to raise_error(ArgumentError, "Can't find step with key: foo")
    end
  end

  describe '#push' do
    it 'pushes to steps' do
      collection.push('Foo')

      expect(collection.steps).to be_include('Foo')
    end
  end

  describe '#to_definition' do
    it 'returns an array of hashes' do
      Buildkite::Pipelines::Steps::Command.new.tap do |step|
        step.process(proc { command 'true' })
        collection.push step
      end

      Buildkite::Pipelines::Steps::Command.new.tap do |step|
        step.process(proc { condition 'false' })
        collection.push step
      end

      expect(collection.to_definition).to eq(
        [
          { 'command' => ['true'] },
          { 'if' => 'false' },
        ]
      )
    end
  end
end
