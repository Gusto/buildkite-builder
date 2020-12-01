# frozen_string_literal: true

require 'logger'

module Spec
  module Support
    module Logging
      def read_logs(truncate: true)
        logs = @buildkite_builder_spec_logger.string
        @buildkite_builder_spec_logger.truncate(0) if truncate
        logs
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Spec::Support::Logging)
  config.before do |example|
    next if example.metadata[:skip_logging_stubs]

    @buildkite_builder_spec_logger = Logger.new(StringIO.new).tap do |logger|
      logger.formatter = proc do |_severity, _datetime, _progname, msg|
        "#{msg}\n"
      end
    end

    allow(Logger).to receive(:new).and_return(@buildkite_builder_spec_logger)
  end
end
