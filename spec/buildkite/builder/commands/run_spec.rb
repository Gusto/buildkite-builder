# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands::Run do
  let(:argv) { [] }
  let(:fixture_project) { :single_pipeline }
  let(:pipeline) { instance_double(Buildkite::Builder::Pipeline) }

  before do
    stub_const('ARGV', argv)
    setup_project(fixture_project)
    stub_buildkite_env(step_id: 'step-id')
  end

  describe '.execute' do
    context 'when step key exists' do
      let(:exists) { true }

      before do
        allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:exists, Buildkite::Builder.meta_data.fetch(:job)).and_return(exists)
      end

      it 'does not upload the pipeline' do
        expect(Buildkite::Builder::Pipeline).not_to receive(:new)

        described_class.execute
      end

      context 'when step key does not exists' do
        let(:exists) { false }

        before do
          allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:exists, Buildkite::Builder.meta_data.fetch(:job)).and_return(exists)
        end

        it 'uploads the context' do
          expect(Buildkite::Builder::Pipeline).to receive(:new).and_return(pipeline)
          expect(pipeline).to receive(:upload)

          described_class.execute
        end
      end
    end
  end
end
