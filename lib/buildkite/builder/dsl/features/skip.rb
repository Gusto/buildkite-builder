# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      module Features
        module Skip
          def skip(template = nil, **args, &block)
            data[:steps] ||= []
            data[:steps].push(Pipelines::Steps::Skip.new(self, find_template(template), **args, &block)).last

            step = add(Pipelines::Steps::Skip, template, **args, &block)
            # A skip step has a nil/noop command.
            step.command(nil)
            # Always set the skip attribute if it's in a falsey state.
            step.skip(true) if !step.get(:skip) || step.skip.empty?
            step
          end
        end
      end
    end
  end
end
