# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Plugin do
  let(:plugin) { described_class.new("#{source}##{version}", options) }
  let(:source) { 'https://foo.com' }
  let(:version) { 'v1.2.3' }
  let(:options) { nil }

  it 'sets source and version' do
    expect(plugin.source).to eq(source)
    expect(plugin.version).to eq(version)
  end

  describe '#to_h' do
    let(:options) do
      {
        'foo' => {
          'bar' => 1,
          'baz' => 2,
        },
      }
    end

    it 'turns source, version, and options to hash' do
      expect(described_class.new("#{source}##{version}", options).to_h).to eq(
        "#{source}##{version}" => {
          'foo' => {
            'bar' => 1,
            'baz' => 2,
          },
        }
      )
    end
  end
end
