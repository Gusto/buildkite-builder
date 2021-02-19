# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands::Run do
  let(:argv) { [] }
  let(:fixture_project) { :single_pipeline }

  before do
    stub_const('ARGV', argv)
    setup_project(fixture_project)
  end

  describe '.execute' do
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

      described_class.execute

      expect(File.exist?(artifact_path)).to eq(false)
      expect(File.exist?(pipeline_path)).to eq(false)
      expect(artifact_contents).to eq(pipeline_contents)
      expect(pipeline_contents).to eq(<<~YAML)
        ---
        steps:
        - label: Basic step
          command:
          - 'true'
      YAML
    end
  end
end
