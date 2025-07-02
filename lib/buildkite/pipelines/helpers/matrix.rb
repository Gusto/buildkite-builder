# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Matrix
        def matrix(value = nil, setup: nil)
          if value.nil? && setup.nil?
            get(:matrix)
          elsif setup
            set(:matrix, { setup: setup })
          else
            set(:matrix, value)
          end
        end
      end
    end
  end
end 