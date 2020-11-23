module Buildkite
  module Converter
    module StepAttributes
      class Label < Abstract
        EMOJI = /:(\w*):\s?/

        def parse
          matches = value.scan(EMOJI).flatten
          matches.map! { |str| ":#{str}" }
          stripped_string = value.gsub(EMOJI, '')

          "#{key} '#{stripped_string}', emoji: [#{matches.join(', ')}]"
        end
      end
    end
  end
end
