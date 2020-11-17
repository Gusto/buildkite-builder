# frozen_string_literal: true

module Buildkite
  module Pipelines
    class Plugin
      attr_reader :uri, :version, :options

      def initialize(uri, version, options = nil)
        @uri = uri
        @version = version
        @options = options
      end

      def full_uri
        "#{uri}##{version}"
      end

      def to_h
        Helpers.sanitize(full_uri => options)
      end
    end
  end
end
