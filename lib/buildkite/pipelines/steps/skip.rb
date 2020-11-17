# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      class Skip < Abstract
        # This skip step is not an official Buildkite step. A skip step is really
        # just a command step that does nothing and is used to portray a hidden
        # step on the Buildkite web UI.
        #
        # Since it is it's own class, pipeline processors will be able to distinguish
        # between this type of skip and a conditional skip. Conditional skips are
        # full command or trigger steps skipped by the `skip` attribute. They can be
        # unskipped in processors for certain situations. See the `DefaultBranch`
        # processor for example.

        # Do NOT sort this list. The order here is carried over to the YAML output.
        # The order specified here was deliberate.
        attribute :label
        attribute :skip
        attribute :if, as: :condition
        attribute :depends_on, append: true
        attribute :allow_dependency_failure
        attribute :command
      end
    end
  end
end
