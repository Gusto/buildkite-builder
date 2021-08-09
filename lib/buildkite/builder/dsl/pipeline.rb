module Buildkite
  module Builder
    module DSL
      class Pipeline < Abstract
        include Features::Env
        include Features::Notify
        include Features::Skip
        include Features::Wait
      end
    end
  end
end
