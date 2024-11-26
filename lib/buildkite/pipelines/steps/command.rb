# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Command < Abstract
        # Do NOT sort this list. The order here is carried over to the YAML output.
        # The order specified here was deliberate.
        attribute :label
        attribute :key
        attribute :command, append: true
        attribute :skip
        attribute :if, as: :condition
        attribute :depends_on, append: true
        attribute :allow_dependency_failure
        attribute :parallelism
        attribute :branches
        attribute :artifact_paths
        attribute :agents
        attribute :concurrency
        attribute :concurrency_group
        attribute :retry
        attribute :env
        attribute :soft_fail, append: true
        attribute :timeout_in_minutes
        attribute :plugins, append: true
        attribute :priority
        attribute :cancel_on_build_failing
      end
    end
  end
end
