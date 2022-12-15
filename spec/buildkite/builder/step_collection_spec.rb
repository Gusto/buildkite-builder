# frozen_string_literal: true

RSpec.describe Buildkite::Builder::StepCollection do
  before do
    setup_project(fixture_project)
  end

  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }

  describe '#each' do
    before do
      pipeline.dsl.command do
        key 'command'
      end

      pipeline.dsl.block do
        key 'block'
      end

      pipeline.dsl.wait do
        key 'wait'
      end
    end

    it 'iterates through steps' do
      keys = []
      pipeline.data.steps.each do |step|
        keys << step.key
      end
      expect(keys).to match_array(['command', 'block', 'wait'])
    end

    context 'with types' do
      it 'iterates through steps with types' do
        pipeline.data.steps.each(:command) do |step|
          expect(step.key).to eq('command')
        end

        pipeline.data.steps.each(:block) do |step|
          expect(step.key).to eq('block')
        end

        pipeline.data.steps.each(:wait) do |step|
          expect(step.key).to eq('wait')
        end

        keys = []
        pipeline.data.steps.each(:command, :block) do |step|
          keys << step.key
        end
        expect(keys).to match_array(['command', 'block'])
      end
    end

    context 'with group' do
      before do
        pipeline.dsl.group do
          label 'group'
          key 'group'
          command { key 'command_in_group' }
          block { key 'block_in_group' }
          wait { key 'wait_in_group' }
        end
      end

      it "also iterates over group's steps" do
        command_keys, block_keys, wait_keys = [], [], []

        pipeline.data.steps.each(:command) do |step|
          command_keys << step.key
        end
        expect(command_keys).to match_array(['command', 'command_in_group'])

        pipeline.data.steps.each(:block) do |step|
          block_keys << step.key
        end
        expect(block_keys).to match_array(['block', 'block_in_group'])

        pipeline.data.steps.each(:wait) do |step|
          wait_keys << step.key
        end
        expect(wait_keys).to match_array(['wait', 'wait_in_group'])
      end

      context 'filter for groups' do
        it "returns group and iterates over group's steps" do
          all, command_keys, block_keys, wait_keys = [], [], [], []

          pipeline.data.steps.each(:group, :command) do |step|
            command_keys << step.key
          end
          expect(command_keys).to match_array(['group', 'command', 'command_in_group'])

          pipeline.data.steps.each(:group, :block) do |step|
            block_keys << step.key
          end
          expect(block_keys).to match_array(['group', 'block', 'block_in_group'])

          pipeline.data.steps.each(:group, :wait) do |step|
            wait_keys << step.key
          end
          expect(wait_keys).to match_array(['group', 'wait', 'wait_in_group'])

          pipeline.data.steps.each do |step|
            all << step.key
          end

          expect(all).to match_array(['block', 'block_in_group', 'command', 'command_in_group', 'group', 'wait', 'wait_in_group'])
        end
      end

      context 'look for group only' do
        it 'only returns group' do
          group_keys = []

          pipeline.data.steps.each(:group) do |step|
            group_keys << step.key
          end

          expect(group_keys).to match_array(['group'])
        end
      end
    end
  end

  describe '#find' do
    let(:collection) { described_class.new }
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
    let(:collection) { described_class.new }
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
    let(:collection) { described_class.new }

    it 'pushes to steps' do
      collection.push('Foo')

      expect(collection.steps).to be_include('Foo')
    end
  end

  describe '#to_definition' do
    let(:collection) { described_class.new }

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
