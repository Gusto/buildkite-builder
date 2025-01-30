# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Plugin do
  let(:plugin) { described_class.new(uri, default_attributes) }
  let(:uri) { "#{source}##{version}" }
  let(:source) { 'https://foo.com' }
  let(:version) { 'v1.2.3' }
  let(:default_attributes) { nil }

  describe '#uri' do
    it "returns the uri" do
      expect(plugin.uri).to eq(uri)
    end
  end

  describe '#default_attributes' do
    it "returns the default attributes" do
      expect(plugin.default_attributes).to eq(default_attributes)
    end
  end

  describe '#source' do
    it 'returns the source' do
      expect(plugin.source).to eq(source)
    end
  end

  describe '#version' do
    it 'returns the version' do
      expect(plugin.version).to eq(version)
    end
  end
end
