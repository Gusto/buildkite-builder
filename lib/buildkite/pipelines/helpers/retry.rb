# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Retry
        def automatic_retry_on(options = {})
          raise 'limit must set for `automatic_retry_on`.' unless options[:limit]

          if !options[:signal_reason] && !options[:exit_status]
            raise 'signal_reason or exit_status must set for `automatic_retry_on`.'
          end

          retry_value = get(:retry) || set(:retry, {})

          unless retry_value[:automatic].is_a?(Array)
            retry_value[:automatic] = []
          end

          automatic_options = { limit: options[:limit] }

          if options[:exit_status] && options[:signal_reason]
            retry_value[:automatic].delete_if do |rule|
              rule[:exit_status] == options[:exit_status] && rule[:signal_reason] == options[:signal_reason]
            end
            automatic_options[:exit_status] = options[:exit_status]
            automatic_options[:signal_reason] = options[:signal_reason]
          elsif options[:exit_status]
            retry_value[:automatic].delete_if { |rule| rule[:exit_status] == options[:exit_status] }
            automatic_options[:exit_status] = options[:exit_status]
          elsif options[:signal_reason]
            retry_value[:automatic].delete_if { |rule| rule[:signal_reason] == options[:signal_reason] }
            automatic_options[:signal_reason] = options[:signal_reason]
          end

          retry_value[:automatic].push(automatic_options)
        end

        def automatic_retry(enabled)
          retry_value = get(:retry) || set(:retry, {})
          retry_value[:automatic] = enabled
        end

        def manual_retry(allowed, reason: nil, permit_on_passed: nil)
          retry_value = get(:retry) || set(:retry, {})
          retry_value[:manual] = { allowed: allowed }
          retry_value[:manual][:reason] = reason unless reason.nil?
          retry_value[:manual][:permit_on_passed] = permit_on_passed unless permit_on_passed.nil?
        end
      end
    end
  end
end
