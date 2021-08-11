# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      module Features
        module Group
          def group(label, &block)
            Builder::Group.new(label, &block)
          end
        end
      end
    end
  end
end
