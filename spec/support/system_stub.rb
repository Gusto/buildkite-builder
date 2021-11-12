# frozen_string_literal: true

module Spec
  module Support
    module SystemStub
      def stub_system_calls
        allow_any_instance_of(Buildkite::Pipelines::Command).to receive(:system).and_return(true)
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Spec::Support::SystemStub)
  config.before { stub_system_calls }
end
