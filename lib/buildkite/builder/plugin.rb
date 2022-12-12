# frozen_string_literal: true

module Buildkite
  module Builder
    class Plugin
      attr_reader \
        :uri,
        :source,
        :version,
        :default_attributes

      def initialize(uri, default_attributes = {})
        @uri = uri
        @source, @version = uri.split('#')
        @default_attributes = default_attributes
      end
    end
  end
end
