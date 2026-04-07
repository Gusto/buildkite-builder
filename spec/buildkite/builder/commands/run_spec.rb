# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands::Run do
  let(:argv) { [] }
  let(:fixture_project) { :single_pipeline }
  let(:pipeline) { instance_double(Buildkite::Builder::Pipeline) }
  let(:result) { instance_double(Buildkite::Pipelines::Command::Result, success?: success) }

  before do
    stub_const('ARGV', argv)
    setup_project(fixture_project)
    stub_buildkite_env(step_id: 'step-id')
  end

  describe '.execute' do
    context 'when step key exists' do
      let(:success) { true }

      before do
        allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:exists, Buildkite::Builder.meta_data.fetch(:job)).and_return(result)
      end

      it 'does not upload the pipeline' do
        expect(Buildkite::Builder::Pipeline).not_to receive(:new)

        described_class.execute
      end

      context 'when step key does not exists' do
        let(:success) { false }

        before do
          allow(Buildkite::Pipelines::Command).to receive(:meta_data).with(:exists, Buildkite::Builder.meta_data.fetch(:job)).and_return(result)
        end

        it 'uploads the context' do
          expect(Buildkite::Builder::Pipeline).to receive(:new).and_return(pipeline)
          allow(pipeline).to receive(:to_h).and_return({ 'steps' => [] })
          allow(pipeline).to receive(:steps).and_return(instance_double(Buildkite::Builder::StepCollection, steps: []))
          expect(pipeline).to receive(:upload)

          described_class.execute
        end

        it 'aborts without uploading when validation fails in strict mode' do
          stub_const('ARGV', ['--strict'])
          expect(Buildkite::Builder::Pipeline).to receive(:new).and_return(pipeline)
          allow(pipeline).to receive(:to_h).and_return({ 'steps' => [] })
          allow(pipeline).to receive(:steps).and_return(instance_double(Buildkite::Builder::StepCollection, steps: []))

          bad_validator = instance_double(
            Buildkite::Builder::Validator,
            validate_all: [
              Buildkite::Builder::Validator::ValidationError.new(
                pointer: '/timeout_in_minutes',
                type: 'integer',
                schema: { 'type' => 'integer' },
                message: 'value is not an integer'
              )
            ]
          )
          allow(Buildkite::Builder::Validator).to receive(:new).and_return(bad_validator)

          expect(pipeline).not_to receive(:upload)

          expect {
            described_class.execute
          }.to raise_error(SystemExit)
        end
      end
    end
  end
end
