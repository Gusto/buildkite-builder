module Buildkite
  module Converter
    module StepAttributes
      class Retry < Abstract
        def parse
          raise ArgumentError, "Expecting a Hash, got a '#{value.class}'" unless value.is_a?(Hash)

          output = []

          if value.include?('automatic')
            retry_conditions = value['automatic']

            retry_conditions.each do |hash|
              status = hash.fetch('exit_status')
              limit = hash.fetch('limit')
              output << "automatically_retry status: #{status}, limit: #{limit}"
            end
          end

          if value.include?('manual')
            raise 'Manual retry is not currently supported in the Buildkite Builder DSL.'
          end

          output
        end
      end
    end
  end
end
