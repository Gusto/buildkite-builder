# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      ATTRIBUTE_HELPERS = {
        block: :Block,
        command: :Command,
        key: :Key,
        label: :Label,
        plugins: :Plugins,
        retry: :Retry,
        skip: :Skip,
        soft_fail: :SoftFail,
        timeout_in_minutes: :TimeoutInMinutes,
      }.freeze

      ATTRIBUTE_HELPERS.each do |name, mod|
        autoload mod, File.expand_path("helpers/#{name}", __dir__)
      end

      def self.prepend_attribute_helper(step_class, attribute)
        if ATTRIBUTE_HELPERS[attribute]
          step_class.prepend(const_get(ATTRIBUTE_HELPERS[attribute]))
        end
      end

      def self.sanitize(obj)
        case obj
        when Hash
          obj.transform_keys(&:to_s).transform_values { |value| sanitize(value) }
        when Array
          obj.map { |value| sanitize(value) }
        when Symbol, Pathname
          obj.to_s
        else
          obj
        end
      end
    end
  end
end
