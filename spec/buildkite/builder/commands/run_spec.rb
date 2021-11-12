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
    let(:job_exists) { false }

    before do
      allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:exists, Buildkite::Builder::META_DATA.fetch(:job)).and_return(job_exists)
    end

    it 'uploads the context' do
      expect(Buildkite::Builder::Pipeline).to receive(:new).and_return(pipeline)
      expect(pipeline).to receive(:upload)

      described_class.execute
    end

    context 'when job exists' do
      let(:job_exists) { true }

      it 'does not upload the pipeline' do
        expect(Buildkite::Builder::Pipeline).not_to receive(:new)

        described_class.execute
      end
    end
  end
end
