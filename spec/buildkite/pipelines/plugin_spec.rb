# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Plugin do
  describe '#to_h' do
    let(:uri) { 'https://foo.com' }
    let(:version) { 'v1.2.3' }
    let(:options) do
      {
        'foo' => {
          'bar' => 1,
          'baz' => 2,
        },
      }
    end

    it 'turns uri, version, and options to hash' do
      expect(described_class.new(uri, version, options).to_h).to eq(
        "#{uri}##{version}" => {
          'foo' => {
            'bar' => 1,
            'baz' => 2,
          },
        }
      )
    end
  end
end
