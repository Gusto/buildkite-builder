module Buildkite
  module Builder
    class Group
      attr_reader :steps, :templates

      def initialize(_context)
        @steps = []
        @templates = _context.templates
      end
    end
  end
end
