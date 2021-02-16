# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Runner do
  describe '#run' do
    before do
      setup_project(fixture_project)
    end

    let(:fixture_project) { :basic_with_shared_and_pipeline_processors }
    let(:pipeline_name) { 'dummy' }
    let(:options) { { pipeline: pipeline_name } }
    let(:runner) { described_class.new(**options) }

    it 'returns the pipeline' do
      expect(runner.run).to be_a(Buildkite::Pipelines::Pipeline)
    end

    context 'when uploading' do
      let(:options) do
        {
          pipeline: pipeline_name,
          upload: true,
        }
      end

      it 'uploads to Buildkite' do
        artifact_path = nil
        pipeline_path = nil
        artifact_contents = nil
        pipeline_contents = nil

        expect(Buildkite::Pipelines::Command).to receive(:artifact!).ordered do |subcommand, path|
          expect(subcommand).to eq(:upload)
          artifact_path = path
          artifact_contents = File.read(path)
        end

        expect(Buildkite::Pipelines::Command).to receive(:pipeline!).ordered do |subcommand, path|
          expect(subcommand).to eq(:upload)
          pipeline_path = path
          pipeline_contents = File.read(path)
        end

        pipeline = runner.run

        expect(File.exist?(artifact_path)).to eq(false)
        expect(File.exist?(pipeline_path)).to eq(false)
        expect(artifact_contents).to eq(pipeline_contents)
        expect(pipeline_contents).to eq(pipeline.to_yaml)
      end
    end
  end
end
