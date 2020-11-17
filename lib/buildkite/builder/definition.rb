# frozen_string_literal: true

module Buildkite
  module Builder
    module Definition
      module Helper
        def load_definition(file, expected)
          result = eval(file.read, TOPLEVEL_BINDING.dup, file.to_s) # rubocop:disable Security/Eval
          unless result.is_a?(expected)
            raise "#{file} must return a valid definition (#{expected}); got #{result.class}"
          end

          result
        end
      end

      class Pipeline < Proc
      end

      class Template < Proc
      end
    end
  end
end
