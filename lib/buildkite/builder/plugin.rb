# frozen_string_literal: true

module Buildkite
  module Builder
    class Plugin
      attr_reader :uri, :source, :version, :attributes

      def initialize(uri, attributes = {})
        @uri = uri
        @source, @version = uri.split('#')
        @attributes = attributes
      end

      def to_h
        Buildkite::Pipelines::Helpers.sanitize(uri => (attributes&.empty? ? nil : attributes))
      end
    end
  end
end
