# frozen_string_literal: true

module Spec
  module Support
    module BuildkiteApi
      def api_response_for_build(state, buildkit: :passed, jobs: [])
        {
          'state' => state.to_s,
          'jobs' => [
            'step_key' => 'buildkite-builder',
            'state' => buildkit.to_s,
          ].concat(jobs),
        }
      end

      def api_response_for_job(step, overrides = {})
        overrides.transform_keys!(&:to_s)
        overrides.transform_values! { |value| value ? value.to_s : value }

        response = {
          'state' => 'passed',
          'name' => step.label.to_s,
        }

        case step
        when Buildkite::Pipelines::Steps::Command
          response['type'] = 'script'
          response['step_key'] = step.key.to_s if step.has?(:key)
        when Buildkite::Pipelines::Steps::Trigger
          response['type'] = 'trigger'
          response['triggered_build'] = {
            'url' => "https://api.buildkite.com/v2/organizations/#{Buildkite.env.organization_slug}/pipelines/#{step.trigger}/builds/12345",
          }
        else raise 'Unknown step type'
        end

        response.merge(overrides)
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Spec::Support::BuildkiteApi)
end
