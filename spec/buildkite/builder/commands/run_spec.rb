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
    context 'when step key matches' do
      before do
        allow(Buildkite).to receive(:env).and_return(OpenStruct.new(step_key: 'step-key'))
        allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:get, Buildkite::Builder.meta_data.fetch(:job)).and_return('step-key')
      end

      it 'does not upload the pipeline' do
        expect(Buildkite::Builder::Pipeline).not_to receive(:new)

        described_class.execute
      end

      context 'when uploaded to different job' do
        before do
          allow(Buildkite).to receive(:env).and_return(OpenStruct.new(step_key: 'another-step-key'))
          allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:get, Buildkite::Builder.meta_data.fetch(:job)).and_return('step-key')
        end

        it 'uploads the context' do
          expect(Buildkite::Builder::Pipeline).to receive(:new).and_return(pipeline)
          expect(pipeline).to receive(:upload)

          described_class.execute
        end
      end

      context 'when not uploaded' do
        before do
          allow(Buildkite).to receive(:env).and_return(OpenStruct.new(step_key: 'step-key'))
          allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:get, Buildkite::Builder.meta_data.fetch(:job)).and_return('')
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
