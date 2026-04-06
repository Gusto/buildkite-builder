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
        }.to raise_error(RuntimeError, 'Your project has multiple pipelines, please specify one.')
      end
    end

    context 'validation integration' do
      before do
        setup_project(:basic)
      end

      it 'validates the pipeline and outputs YAML when valid' do
        expect {
          described_class.execute
        }.to output(/steps:/).to_stdout
      end

      context 'with --no-validate flag' do
        let(:argv) { ['--no-validate'] }

        it 'skips validation and outputs YAML' do
          expect(Buildkite::Builder::Validator).not_to receive(:new)
          expect {
            described_class.execute
          }.to output(/steps:/).to_stdout
        end
      end

      context 'with --warn flag and an invalid pipeline' do
        let(:argv) { ['--warn'] }

        it 'prints warnings to stderr but still outputs YAML' do
          bad_validator = instance_double(
            Buildkite::Builder::Validator,
            validate_all: [
              Buildkite::Builder::Validator::ValidationError.new(
                pointer: '/steps/0/timeout_in_minutes',
                message: 'value is not an integer'
              )
            ]
          )
          allow(Buildkite::Builder::Validator).to receive(:new).and_return(bad_validator)

          expect {
            described_class.execute
          }.to output(/steps:/).to_stdout
        end
      end
    end
  end
end
