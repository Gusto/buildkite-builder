# frozen_string_literal: true

module Buildkite
  module Builder
    class Plugin
      attr_reader :uri, :source, :version, :options

      def initialize(uri, options = nil)
        @uri = uri
        @source, @version = uri.split('#')
        @version = version
        @options = options
      end

      def to_h
        Helpers.sanitize(uri => options)
      end
    end
  end
end
