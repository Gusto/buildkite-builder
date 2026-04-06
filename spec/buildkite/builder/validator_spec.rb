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
      expect(errors.first.message).to be_a(String)
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
