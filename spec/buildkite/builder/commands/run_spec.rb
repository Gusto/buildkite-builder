# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands::Run do
  let(:argv) { [] }
  let(:fixture_project) { :single_pipeline }
  let(:pipeline) { instance_double(Buildkite::Builder::Pipeline) }

  before do
    stub_const('ARGV', argv)
    setup_project(fixture_project)
  end

  describe '.execute' do
    it 'uplaods the context' do
      expect(Buildkite::Builder::Pipeline).to receive(:new).and_return(pipeline)
      expect(pipeline).to receive(:upload)

      described_class.execute
    end
  end
end
