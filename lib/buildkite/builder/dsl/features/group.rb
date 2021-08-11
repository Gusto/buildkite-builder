# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      module Features
        module Group
          def group(label = nil, &block)
            group_context = Buildkite::Builder::Group.new(_context)
            group_dsl = Buildkite::Builder::Dsl::Group.new(group_context)
            group_dsl.instance_eval(&block)

            _context.groups << { group: label, steps: group_context.steps }
          end
        end
      end
    end
  end
end
