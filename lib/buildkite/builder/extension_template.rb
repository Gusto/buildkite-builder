module Buildkite
  module Builder
    class ExtensionTemplate
      attr_reader :extension_class, :name, :block

      def initialize(extension_class, name, block)
        @extension_class = extension_class
        @name = name
        @block = block
      end
    end
  end
end
