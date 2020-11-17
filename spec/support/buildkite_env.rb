# frozen_string_literal: true

module Spec
  module Support
    module BuildkiteEnv
      def stub_buildkite_env(env)
        if env
          env = {
            buildkite: true,
          }.merge(env)

          env.transform_keys! { |key| key == :buildkite ? key.to_s.upcase : "BUILDKITE_#{key.to_s.upcase}" }
          env.transform_values!(&:to_s)

          allow(Buildkite).to receive(:env).and_return(Buildkite::Env.new(env))
        else
          allow(Buildkite).to receive(:env)
        end
      end
    end
  end
end

RSpec.configure do |spec|
  spec.include(Spec::Support::BuildkiteEnv)
  spec.before do
    allow(Buildkite).to receive(:env).and_return(nil)
  end
end
