# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands::Run do
  let(:argv) { [] }
  let(:fixture_project) { :single_pipeline }
  let(:context) { instance_double(Buildkite::Builder::Context) }

  before do
    stub_const('ARGV', argv)
    setup_project(fixture_project)
  end

  describe '.execute' do
    it 'uplaods the context' do
      expect(Buildkite::Builder::Context).to receive(:new).and_return(context)
      expect(context).to receive(:upload)

      described_class.execute
    end
  end
end
