# frozen_string_literal: true

RSpec.describe Buildkite::Builder::StepCollection do
  let(:root) { Buildkite::Builder.root }
  let(:collection) { described_class.new(Buildkite::Builder::TemplateRegistry.new(root), Buildkite::Builder::PluginRegistry.new) }

  describe '#each' do
    before do
      collection.add(Buildkite::Pipelines::Steps::Command) do
        key 'command'
      end
      collection.add(Buildkite::Pipelines::Steps::Block) do
        key 'block'
      end
      collection.add(Buildkite::Pipelines::Steps::Wait) do
        key 'wait'
      end
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
        group = Buildkite::Builder::Group.new('group', collection) do
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

  describe '#add' do
    it 'adds to steps' do
      step = collection.add(Buildkite::Pipelines::Steps::Command)

      expect(step).to be_a(Buildkite::Pipelines::Steps::Command)
      expect(collection.steps).to be_include(step)
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
      collection.add(Buildkite::Pipelines::Steps::Command) do
        command 'true'
      end

      collection.add(Buildkite::Pipelines::Steps::Command) do
        condition 'false'
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
