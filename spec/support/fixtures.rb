# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module Spec
  module Support
    module Fixtures
      def fixture_path_for(project)
        Pathname.new('tmp/fixtures').join(project.to_s).expand_path
      end

      def fixture_buildkite_path_for(project)
        fixture_path_for(project).join(Buildkite::Builder::BUILDKITE_DIRECTORY_NAME)
      end

      def fixture_pipeline_path_for(project, pipeline)
        fixture_buildkite_path_for(project).join(Buildkite::Builder::Runner::PIPELINES_PATH).join(pipeline.to_s)
      end

      def setup_project(project)
        destination = setup_project_fixture(project)

        stub_buildkit_root(destination)
      end

      def setup_project_fixture(project)
        source = Pathname.new("spec/fixtures/#{project}").expand_path
        destination = Pathname.new("tmp/fixtures/#{project}").expand_path
        destination.dirname.mkpath

        FileUtils.cp_r(source.to_s, destination.to_s)

        destination
      end

      def stub_buildkit_root(destination)
        allow(Buildkite::Builder).to receive(:root).and_return(destination)
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Spec::Support::Fixtures)
  config.before do
    Buildkite::Builder.instance_variable_set :@root, nil
  end
  config.after do
    FileUtils.rm_rf('tmp/fixtures')
  end
end
