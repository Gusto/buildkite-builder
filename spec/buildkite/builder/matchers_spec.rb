# frozen_string_literal: true

require 'buildkite/builder/matchers'

RSpec.describe Buildkite::Builder::Matchers do
  include Buildkite::Builder::Matchers

  describe 'be_valid_pipeline' do
    context 'with a valid pipeline hash' do
      let(:pipeline_hash) { { 'steps' => [{ 'command' => 'echo hello', 'label' => 'test' }] } }

      it 'passes' do
        expect(pipeline_hash).to be_valid_pipeline
      end
    end

    context 'with an invalid pipeline hash' do
      let(:pipeline_hash) { {} }

      it 'fails with an error message listing the violations' do
        expect {
          expect(pipeline_hash).to be_valid_pipeline
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected pipeline to be valid/)
      end

      it 'includes error count in the failure message' do
        expect {
          expect(pipeline_hash).to be_valid_pipeline
        }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /error\(s\)/)
      end
    end

    context 'with .with_schema chained' do
      let(:pipeline_hash) { { 'steps' => [{ 'command' => 'echo hello' }] } }
      let(:default_schema) { Buildkite::Builder::Validator.default_schema_path }

      it 'uses the specified schema' do
        expect(pipeline_hash).to be_valid_pipeline.with_schema(default_schema)
      end
    end

    context 'with a real fixture pipeline' do
      before { setup_project(:basic) }

      it 'validates a real pipeline built from DSL' do
        pipeline_path = fixture_pipeline_path_for(:basic, :dummy)
        pipeline_hash = Buildkite::Builder::Pipeline.new(pipeline_path).to_h
        expect(pipeline_hash).to be_valid_pipeline
      end
    end
  end
end
