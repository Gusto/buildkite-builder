# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Block < Abstract
        # Do NOT sort this list. The order here is carried over to the YAML output.
        # The order specified here was deliberate.
        attribute :block
        attribute :key
        attribute :prompt
        attribute :skip
        attribute :if, as: :condition
        attribute :depends_on, append: true
        attribute :allow_dependency_failure
        attribute :branches
        attribute :fields
        attribute :blocked_state
        attribute :allowed_teams, append: true
      end
    end
  end
end
