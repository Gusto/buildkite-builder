require 'bundler/setup'
require 'buildkite-builder'
require 'debug'
require 'webmock/rspec'

Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require_relative f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random
end
