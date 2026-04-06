# frozen_string_literal: true

require 'json_schemer'
require 'pathname'

module Buildkite
  module Builder
    class Validator
      ValidationError = Struct.new(:pointer, :message, keyword_init: true)

      def initialize(schema_path: nil)
        path = schema_path || self.class.default_schema_path
        @schemer = JSONSchemer.schema(Pathname.new(path.to_s))
      end

      def validate(pipeline_hash)
        @schemer.validate(pipeline_hash).map do |error|
          ValidationError.new(
            pointer: error['data_pointer'],
            message: error['error']
          )
        end
      end

      def valid?(pipeline_hash)
        @schemer.valid?(pipeline_hash)
      end

      def self.default_schema_path
        File.expand_path('schema.json', __dir__)
      end
    end
  end
end
