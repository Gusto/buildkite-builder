# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands::Preview do
  let(:argv) { [] }

  before do
    stub_const('ARGV', argv)
  end

  describe '.execute' do
    context 'when project has one pipeline' do
      before do
        setup_project(:basic)
      end

      it 'does not require specifying a pipeline' do
        expect {
          described_class.execute
        }.to output(/steps:/).to_stdout
      end
    end

    context 'when project has multiple pipelines' do
      before do
        setup_project(:multipipeline)
      end

      it 'requires specifying a pipeline' do
        expect {
          described_class.execute
        }.to raise_error(RuntimeError, 'You must specify a pipeline')
      end
    end
  end
end
