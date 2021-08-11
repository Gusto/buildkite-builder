module Buildkite
  module Builder
    module Dsl
      class Abstract
        attr_reader :_context

        def initialize(_context)
          @_context = _context
        end
      end
    end
  end
end
