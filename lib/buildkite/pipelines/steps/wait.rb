# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Wait < Abstract
        # Do NOT sort this list. The order here is carried over to the YAML output.
        # The order specified here was deliberate.
        attribute :wait
        attribute :key
        attribute :if, as: :condition
        attribute :depends_on, append: true
        attribute :allow_dependency_failure
        attribute :continue_on_failure
      end
    end
  end
end
