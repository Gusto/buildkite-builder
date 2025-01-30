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

      it "does not iterate over group's steps when opted out" do
        keys = []

        pipeline.data.steps.each(traverse_groups: false) do |step|
          keys << step.key
        end
        expect(keys).to_not include('command_in_group')
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
        step.key(:command)
        collection.push step
      end
    end
    let!(:block_step) do
      Buildkite::Pipelines::Steps::Block.new.tap do |step|
        step.key(:block)
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
        step.key(:command)
        collection.push step
      end
    end
    let!(:block_step) do
      Buildkite::Pipelines::Steps::Block.new.tap do |step|
        step.key(:block)
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

  describe '#remove' do
    let(:collection) { described_class.new }

    it 'removes the steps and returns it' do
      command = Buildkite::Pipelines::Steps::Command.new
      collection.push(command)

      expect(collection.remove(command)).to eq(command)
    end
  end

  describe '#replace' do
    let(:collection) { described_class.new }

    it 'swaps out the step' do
      command = Buildkite::Pipelines::Steps::Command.new
      collection.push(command)
      block = Buildkite::Pipelines::Steps::Block.new
      collection.push(block)
      trigger = Buildkite::Pipelines::Steps::Trigger.new
      collection.replace(command, trigger)

      expect(collection.steps).to eq([trigger, block])
    end
  end

  describe '#move' do
    let(:collection) { described_class.new }

    it 'moves the step before another step' do
      command = Buildkite::Pipelines::Steps::Command.new
      collection.push(command)
      block = Buildkite::Pipelines::Steps::Block.new
      collection.push(block)
      wait = Buildkite::Pipelines::Steps::Wait.new
      collection.push(wait)

      collection.move(wait, before: block)

      expect(collection.steps).to eq([command, wait, block])
    end

    it 'moves the step after another step' do
      command = Buildkite::Pipelines::Steps::Command.new
      collection.push(command)
      block = Buildkite::Pipelines::Steps::Block.new
      collection.push(block)
      wait = Buildkite::Pipelines::Steps::Wait.new
      collection.push(wait)

      collection.move(wait, after: command)

      expect(collection.steps).to eq([command, wait, block])
    end

    it 'raises an error if before and after are both specified' do
      expect {
        collection.move(Buildkite::Pipelines::Steps::Command.new, before: 'foo', after: 'bar')
      }.to raise_error(ArgumentError, 'Specify either before or after')
    end

    it 'raises an error if neither before nor after are specified' do
      expect {
        collection.move(Buildkite::Pipelines::Steps::Command.new)
      }.to raise_error(ArgumentError, 'Specify before or after')
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
        step.command('true')
        collection.push step
      end

      Buildkite::Pipelines::Steps::Command.new.tap do |step|
        step.condition('false')
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
