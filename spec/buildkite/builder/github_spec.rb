# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Github do
  let(:env) do
    {
      'GITHUB_API_TOKEN' => 'some_api_token',
    }
  end
  let(:github) { described_class.new(env) }
  let(:repo_url) { 'github.com/Gusto/buildkite-builder.git' }

  before do
    stub_buildkite_env(repo: repo_url, pull_request: '12345')
  end

  describe '#pull_request_files' do
    subject { github.pull_request_files }
    let(:init_uri) { URI.join(described_class::BASE_URI, "repos/Gusto/buildkite-builder/pulls/12345/files?per_page=#{described_class::PER_PAGE}") }
    let(:response_1) do
      instance_double(Net::HTTPOK, body: JSON.dump(files_page_1))
    end
    let(:response_2) do
      instance_double(Net::HTTPOK, body: JSON.dump(files_page_2))
    end
    let(:response_3) do
      instance_double(Net::HTTPOK, body: JSON.dump(files_page_3))
    end
    
    let(:files_page_1) { ['file_1', 'file_2'] }
    let(:files_page_2) { ['file_3', 'file_4'] }
    let(:files_page_3) { ['file_5', 'file_6'] }

    context 'when has no next uri' do
      before do
        allow(Net::HTTP).to receive(:start).with(init_uri.hostname, init_uri.port, use_ssl: true).and_return(response_1)
        allow(response_1).to receive(:[]).with(described_class::LINK_HEADER).and_return('links')
      end

      it 'returns files from first page' do
        expect(subject).to eq(files_page_1)
      end
    end

    context 'when has next links' do
      let(:next_uri_1) { URI.join(described_class::BASE_URI, 'repos/Gusto/buildkite-builder/pulls/12345/files?page=2') }
      let(:next_uri_2) { URI.join(described_class::BASE_URI, 'repos/Gusto/buildkite-builder/pulls/12345/files?page=3') }
      let(:links_1) { "<#{next_uri_1}>; rel=\"next\"" }
      let(:links_2) { "<#{next_uri_2}>; rel=\"next\"" }
      let(:http_init) { instance_double(Net::HTTP, 'init') }
      let(:http_1) { instance_double(Net::HTTP, 'page_2') }
      let(:http_2) { instance_double(Net::HTTP, 'page_3') }

      it 'concats files' do
        expect(Net::HTTP).to receive(:start).with(init_uri.hostname, init_uri.port, use_ssl: true).ordered.and_yield(http_init)
        expect(Net::HTTP::Get).to receive(:new).with(init_uri).and_return(spy)
        expect(http_init).to receive(:request).with(anything).and_return(response_1)
        expect(response_1).to receive(:[]).with(described_class::LINK_HEADER).and_return(links_1)

        expect(Net::HTTP).to receive(:start).with(next_uri_1.hostname, next_uri_1.port, use_ssl: true).ordered.and_yield(http_1)
        expect(Net::HTTP::Get).to receive(:new).with(next_uri_1).and_return(spy)
        expect(http_1).to receive(:request).with(anything).and_return(response_2)
        expect(response_2).to receive(:[]).with(described_class::LINK_HEADER).and_return(links_2)

        expect(Net::HTTP).to receive(:start).with(next_uri_2.hostname, next_uri_2.port, use_ssl: true).ordered.and_yield(http_2)
        expect(Net::HTTP::Get).to receive(:new).with(next_uri_2).and_return(spy)
        expect(http_2).to receive(:request).with(anything).and_return(response_3)
        expect(response_3).to receive(:[]).with(described_class::LINK_HEADER).and_return(nil)

        expect(subject).to eq(files_page_1 + files_page_2 + files_page_3)
      end
    end

    context 'when has no .git extenion for Buildkite.env.repo' do
      let(:repo_url) { 'git@github.com/Gusto/buildkite-builder' }

      it 'calls a valid API endpoint' do
        expect(URI).to receive(:join).with(described_class::BASE_URI, "repos/Gusto/buildkite-builder/pulls/12345/files?per_page=100")
        subject
      end
    end
  end

  describe '#pull_request' do
    subject { github.pull_request }
    let(:init_uri) { URI.join(described_class::BASE_URI, "repos/Gusto/buildkite-builder/pulls/12345") }
    let(:response_1) do
      instance_double(Net::HTTPOK, body: JSON.dump(pull_request_response))
    end
    let(:pull_request_response) do 
      # subset of expected response fields from https://docs.github.com/en/rest/pulls/pulls#get-a-pull-request
      {
        'url' => 'https://api.github.com/repos/Gusto/buildkite-builder/pulls/12345',
        'id' => 1,
        'node_id' => 'MDExOlB1bGxSZXF1ZXN0MQ==',
        'html_url' => 'https://github.com/Gusto/buildkite-builder/pull/1347',
        'diff_url' => 'https://github.com/Gusto/buildkite-builder/pull/1347.diff',
        'patch_url' => 'https://github.com/Gusto/buildkite-builder/pull/1347.patch',
        'draft' => false,
        'merged' => false,
        'mergeable' => true,
        'rebaseable' => true,
        'mergeable_state' => 'clean',
        'comments' => 10,
        'review_comments' => 0,
        'maintainer_can_modify' => true,
        'commits' => 3,
        'additions' => 100,
        'deletions' => 3,
        'changed_files' => 5
      } 
    end

    before do
      allow(Net::HTTP).to receive(:start).with(init_uri.hostname, init_uri.port, use_ssl: true).and_return(response_1)
    end

    it 'returns a pull request response' do
      expect(subject).to eq(pull_request_response)
    end
  end
end
