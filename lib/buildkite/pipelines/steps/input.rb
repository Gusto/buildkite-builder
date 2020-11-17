# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Input < Abstract
        # Do NOT sort this list. The order here is carried over to the YAML output.
        # The order specified here was deliberate.
        attribute :input
        attribute :key
        attribute :prompt
        attribute :if, as: :condition
        attribute :depends_on, append: true
        attribute :allow_dependency_failure
        attribute :branches
        attribute :fields
      end
    end
  end
end
