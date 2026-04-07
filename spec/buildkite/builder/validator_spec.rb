# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Validator do
  subject(:validator) { described_class.new }

  describe '#valid?' do
    it 'returns true for a valid pipeline' do
      pipeline = { 'steps' => [{ 'command' => 'echo hello', 'label' => 'test' }] }
      expect(validator.valid?(pipeline)).to be true
    end

    it 'returns false when steps key is missing' do
      expect(validator.valid?({})).to be false
    end

    it 'returns false for an invalid step property type' do
      pipeline = { 'steps' => [{ 'command' => 'echo hello', 'timeout_in_minutes' => 'thirty' }] }
      expect(validator.valid?(pipeline)).to be false
    end
  end

  describe '#validate' do
    it 'returns an empty array for a valid pipeline' do
      pipeline = { 'steps' => [{ 'command' => 'echo hello', 'label' => 'test' }] }
      expect(validator.validate(pipeline)).to be_empty
    end

    it 'returns ValidationError objects with pointer and message for invalid pipeline' do
      errors = validator.validate({})
      expect(errors).not_to be_empty
      expect(errors.first).to be_a(Buildkite::Builder::Validator::ValidationError)
      expect(errors.first.pointer).to be_a(String)
      expect(errors.first.formatted_message).to be_a(String)
    end

    it 'reports the correct pointer for an invalid step property' do
      pipeline = { 'steps' => [{ 'command' => 'echo hello', 'timeout_in_minutes' => 'thirty' }] }
      errors = validator.validate(pipeline)
      expect(errors).not_to be_empty
      expect(errors.any? { |e| e.pointer.include?('timeout_in_minutes') }).to be true
    end

    it 'accepts a custom schema path' do
      custom_validator = described_class.new(schema_path: described_class.default_schema_path)
      pipeline = { 'steps' => [{ 'command' => 'echo hello' }] }
      expect(custom_validator.valid?(pipeline)).to be true
    end
  end

  describe '.default_schema_path' do
    it 'returns a path to an existing file' do
      expect(File.exist?(described_class.default_schema_path)).to be true
    end
  end

  describe '#validate_all' do
    before { setup_project(:basic) }

    let(:pipeline) do
      Buildkite::Builder::Pipeline.new(fixture_pipeline_path_for(:basic, :dummy))
    end

    it 'returns no errors for a valid pipeline' do
      hash = pipeline.to_h
      errors = validator.validate_all(hash, pipeline.data.steps)
      expect(errors).to be_empty, "Expected no errors but got:\n#{errors.map { |e| "  #{e.pointer}: #{e.message}" }.join("\n")}"
    end

    it 'returns per-step errors with source locations when a step is invalid' do
      hash = pipeline.to_h
      hash['steps'][0]['timeout_in_minutes'] = 'not-a-number'

      errors = validator.validate_all(hash, pipeline.data.steps)
      step_errors = errors.select { |e| e.source_location }

      expect(step_errors).not_to be_empty
      expect(step_errors.first.source_location).to be_a(Buildkite::Pipelines::SourceLocation)
      expect(step_errors.first.source_location.file).to include('.rb')
      expect(step_errors.first.source_location.line_number).to be_an(Integer)
    end

    it 'works without a step collection (falls back to pipeline-level errors only)' do
      errors = validator.validate_all({})
      expect(errors).not_to be_empty
    end

    it 'validates nested steps inside a group step' do
      setup_project(:multipipeline)
      group_pipeline = Buildkite::Builder::Pipeline.new(fixture_pipeline_path_for(:multipipeline, :dummy1))
      hash = group_pipeline.to_h

      # Build a group hash with an invalid nested step
      group_hash = { 'group' => nil, 'steps' => [{ 'command' => 'echo', 'timeout_in_minutes' => 'bad' }] }
      hash['steps'] = [group_hash]

      # Build a matching group step object with a nested command step
      group_step = instance_double(
        Buildkite::Pipelines::Steps::Group,
        source_location: nil
      )
      allow(group_step).to receive(:is_a?).with(Buildkite::Pipelines::Steps::Group).and_return(true)

      inner_step = instance_double(
        Buildkite::Pipelines::Steps::Command,
        source_location: Buildkite::Pipelines::SourceLocation.new(file: 'pipeline.rb', line_number: 5),
        class: Buildkite::Pipelines::Steps::Command
      )
      allow(inner_step).to receive(:is_a?).with(Buildkite::Pipelines::Steps::Group).and_return(false)

      inner_collection = instance_double(Buildkite::Builder::StepCollection, steps: [inner_step])
      allow(group_step).to receive(:steps).and_return(inner_collection)

      step_collection = instance_double(Buildkite::Builder::StepCollection, steps: [group_step])
      errors = validator.validate_all(hash, step_collection)
      step_errors = errors.select { |e| e.source_location }

      expect(step_errors).not_to be_empty
      expect(step_errors.first.source_location.file).to eq('pipeline.rb')
    end
  end

  describe Buildkite::Builder::Validator::ValidationError do
    describe '#attribute' do
      it 'returns the last segment of the pointer' do
        error = described_class.new({ 'data_pointer' => '/steps/0/timeout_in_minutes' })
        expect(error.attribute).to eq('timeout_in_minutes')
      end

      it 'returns "pipeline" when pointer is empty' do
        error = described_class.new({ 'data_pointer' => '' })
        expect(error.attribute).to eq('pipeline')
      end
    end

    describe '#formatted_message' do
      it 'formats integer type errors with correct article' do
        error = described_class.new({ 'type' => 'integer' })
        expect(error.formatted_message).to eq('must be an integer')
      end

      it 'formats string type errors with correct article' do
        error = described_class.new({ 'type' => 'string' })
        expect(error.formatted_message).to eq('must be a string')
      end

      it 'formats enum errors listing allowed values' do
        error = described_class.new({ 'type' => 'enum', 'schema' => { 'enum' => ['ordered', 'eager'] } })
        expect(error.formatted_message).to eq('must be one of: "ordered", "eager"')
      end

      it 'formats required errors using details missing_keys' do
        error = described_class.new({ 'type' => 'required', 'schema' => { 'required' => %w[steps env] }, 'details' => { 'missing_keys' => ['steps'] } })
        expect(error.formatted_message).to eq('is missing required attributes: steps')
      end

      it 'formats additionalProperties errors as unrecognized attribute' do
        error = described_class.new({ 'type' => 'schema' })
        expect(error.formatted_message).to eq('is not a recognized attribute')
      end

      it 'formats minimum errors with threshold' do
        error = described_class.new({ 'type' => 'minimum', 'schema' => { 'minimum' => 1 } })
        expect(error.formatted_message).to eq('must be at least 1')
      end

      it 'formats maximum errors with threshold' do
        error = described_class.new({ 'type' => 'maximum', 'schema' => { 'maximum' => 10 } })
        expect(error.formatted_message).to eq('must be at most 10')
      end

      it 'formats pattern errors' do
        error = described_class.new({ 'type' => 'pattern' })
        expect(error.formatted_message).to eq('does not match expected format')
      end

      it 'formats minItems errors with count' do
        error = described_class.new({ 'type' => 'minItems', 'schema' => { 'minItems' => 1 } })
        expect(error.formatted_message).to eq('must have at least 1 item(s)')
      end

      it 'falls back to raw message for unknown error types' do
        error = described_class.new({ 'type' => 'custom_thing', 'error' => 'something went wrong' })
        expect(error.formatted_message).to eq('something went wrong')
      end
    end

    describe '#to_s' do
      it 'includes source location when present' do
        loc = Buildkite::Pipelines::SourceLocation.new(file: 'pipeline.rb', line_number: 42)
        error = described_class.new({ 'data_pointer' => '/timeout_in_minutes', 'type' => 'integer' }, source_location: loc)
        expect(Rainbow::StringUtils.uncolor(error.to_s)).to eq("pipeline.rb:42 timeout_in_minutes: must be an integer")
      end

      it 'omits location prefix when source_location is nil' do
        error = described_class.new({ 'data_pointer' => '/timeout_in_minutes', 'type' => 'integer' })
        expect(Rainbow::StringUtils.uncolor(error.to_s)).to eq("timeout_in_minutes: must be an integer")
      end
    end
  end

  describe 'compatibility with fixture pipeline output' do
    before { setup_project(:basic) }

    it 'validates the basic fixture pipeline without errors' do
      pipeline_path = fixture_pipeline_path_for(:basic, :dummy)
      pipeline_hash = Buildkite::Builder::Pipeline.new(pipeline_path).to_h
      errors = validator.validate(pipeline_hash)
      expect(errors).to be_empty, "Expected no validation errors but got:\n#{errors.map { |e| "  #{e.pointer}: #{e.message}" }.join("\n")}"
    end
  end
end
