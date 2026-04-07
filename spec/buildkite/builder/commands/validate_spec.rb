# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands::Validate do
  let(:argv) { [] }

  before do
    stub_const('ARGV', argv)
  end

  describe '.execute' do
    context 'with a valid pipeline' do
      before do
        setup_project(:basic)
      end

      it 'prints success and exits cleanly' do
        expect {
          described_class.execute
        }.to output(/Pipeline is valid\./).to_stderr
      end
    end

    context 'with an invalid pipeline (default warn mode)' do
      before do
        setup_project(:basic)
      end

      it 'prints warnings without aborting' do
        bad_validator = instance_double(
          Buildkite::Builder::Validator,
          validate_all: [
            Buildkite::Builder::Validator::ValidationError.new(
              { 'data_pointer' => '/timeout_in_minutes', 'type' => 'integer', 'error' => 'value is not an integer' }
            )
          ]
        )
        allow(Buildkite::Builder::Validator).to receive(:new).and_return(bad_validator)

        expect {
          described_class.execute
        }.not_to raise_error
      end
    end

    context 'with a custom --schema flag' do
      before do
        setup_project(:basic)
      end

      let(:argv) { ['--schema', Buildkite::Builder::Validator.default_schema_path] }

      it 'uses the specified schema and validates successfully' do
        expect {
          described_class.execute
        }.to output(/Pipeline is valid\./).to_stderr
      end
    end

    context 'with --strict flag and an invalid pipeline' do
      before do
        setup_project(:basic)
      end

      let(:argv) { ['--strict'] }

      it 'aborts with an error count' do
        bad_validator = instance_double(
          Buildkite::Builder::Validator,
          validate_all: [
            Buildkite::Builder::Validator::ValidationError.new(
              { 'data_pointer' => '/timeout_in_minutes', 'type' => 'integer', 'error' => 'value is not an integer' }
            )
          ]
        )
        allow(Buildkite::Builder::Validator).to receive(:new).and_return(bad_validator)

        expect {
          described_class.execute
        }.to raise_error(SystemExit)
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
  end
end
