# frozen_string_literal: true

module Buildkite
  module Builder
    class Plugin
      attr_reader :uri, :source, :version, :options

      def initialize(uri, options = nil)
        @uri = uri
        @source, @version = uri.split('#')
        @options = options
      end

      def to_h
        Buildkite::Pipelines::Helpers.sanitize(uri => options)
      end
    end
  end
end
