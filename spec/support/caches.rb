# frozen_string_literal: true

# Turn off caching for tests.
Buildkite::Builder::FileResolver.cache = false

RSpec.configure do |config|
  config.before do
    allow(Buildkite::Builder::Manifest).to receive(:manifests).and_return({})
  end
end
