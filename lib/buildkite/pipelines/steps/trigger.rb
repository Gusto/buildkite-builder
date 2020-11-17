# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Trigger < Abstract
        # Do NOT sort this list. The order here is carried over to the YAML output.
        # The order specified here was deliberate.
        attribute :label
        attribute :key
        attribute :trigger
        attribute :skip
        attribute :if, as: :condition
        attribute :depends_on, append: true
        attribute :allow_dependency_failure
        attribute :branches
        attribute :async
        attribute :build
      end
    end
  end
end
