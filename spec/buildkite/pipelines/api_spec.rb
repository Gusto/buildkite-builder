# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Api do
  let(:token) { 'FOOBAR' }
  let(:organization) { 'gusto-open-source' }
  let(:pipeline) { 'buildkite-builder' }
  let(:build) { 123 }
  let(:client) { described_class.new(token) }

  describe '#get_pipeline_builds' do
    it 'returns the builds' do
      response = [
        { 'foo' => 'bar' },
      ]
      stub_request(:get, 'https://api.buildkite.com/v2/organizations/gusto-open-source/pipelines/buildkite-builder/builds?branch=development').
        with(
          headers: {
            'Accept' => 'application/json',
            'Authorization' => 'Bearer FOOBAR',
          }
        ).
        to_return(status: 200, body: JSON.dump(response), headers: {})

      expect(client.get_pipeline_builds(organization, pipeline, branch: 'development')).to eq(response)
    end
  end

  describe '#get_build' do
    it 'returns the build' do
      response = {
        'foo' => 'bar',
      }
      stub_request(:get, 'https://api.buildkite.com/v2/organizations/gusto-open-source/pipelines/buildkite-builder/builds/123').
        with(
          headers: {
            'Accept' => 'application/json',
            'Authorization' => 'Bearer FOOBAR',
          }
        ).
        to_return(status: 200, body: JSON.dump(response), headers: {})

      expect(client.get_build(organization, pipeline, build)).to eq(response)
    end
  end
end
