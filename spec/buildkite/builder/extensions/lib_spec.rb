# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Lib do
  describe '#prepare' do
    context 'when lib exists' do
      let(:fixture_project) { :basic_with_lib }
      let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }

      before do
        setup_project(fixture_project)
      end

      after do
        $LOAD_PATH.delete_if { |load_path| load_path == Buildkite::Builder.root.join(Buildkite::Builder::BUILDKITE_DIRECTORY_NAME, 'lib') }
      end

      it 'adds .buildkite/lib to load path' do
        Buildkite::Builder::Pipeline.new(fixture_path)

        expect($LOAD_PATH).to be_include(Buildkite::Builder.root.join(Buildkite::Builder::BUILDKITE_DIRECTORY_NAME, 'lib'))
      end
    end

    context 'without lib' do
      let(:fixture_project) { :basic }
      let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }

      before do
        setup_project(fixture_project)
      end

      it 'adds .buildkite/lib to load path' do
        Buildkite::Builder::Pipeline.new(fixture_path)

        expect($LOAD_PATH).not_to be_include(Buildkite::Builder.root.join(Buildkite::Builder::BUILDKITE_DIRECTORY_NAME, 'lib'))
      end
    end
  end
end
