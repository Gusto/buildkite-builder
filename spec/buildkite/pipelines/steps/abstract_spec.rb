# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Steps::Abstract do
  let(:step) { step_class.new }
  let(:step_class) do
    stub_const(
      'Buildkite::Pipelines::Steps::Foo',
      Class.new(described_class) do
        attribute :foo_attribute
        attribute :bar_attribute
      end
    )
  end

  describe '#process' do
    it 'evals the block' do
      block = proc do
        foo_attribute '1'
        bar_attribute '2'
      end

      step.process(block)

      expect(step.foo_attribute).to eq('1')
      expect(step.bar_attribute).to eq('2')
    end

    it 'captures the source location of the block' do
      block = proc { foo_attribute '1' }
      expected_file, expected_line = block.source_location

      step.process(block)

      expect(step.source_location).to be_a(Buildkite::Pipelines::SourceLocation)
      expect(step.source_location.file).to eq(expected_file)
      expect(step.source_location.line_number).to eq(expected_line)
    end

    it 'overwrites source location when processing multiple blocks' do
      first_block = proc { foo_attribute '1' }
      second_block = proc { bar_attribute '2' }
      _, second_line = second_block.source_location

      step.process(first_block)
      step.process(second_block)

      expect(step.source_location.line_number).to eq(second_line)
    end
  end
end
