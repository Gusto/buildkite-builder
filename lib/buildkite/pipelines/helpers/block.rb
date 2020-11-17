# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Helpers
      module Block
        def block(*args, emoji: nil)
          if emoji
            emoji = Array(emoji).map { |name| ":#{name}:" }.join
            args[0] = [emoji, args.first].compact.join(' ')
          end

          super(*args)
        end
      end
    end
  end
end
