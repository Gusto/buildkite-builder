module Buildkite
  module Builder
    module DSL
      class Pipeline < Abstract
        include Features::Env
        include Features::Notify
        include Features::Skip
        include Features::Wait
        include Features::Block
        include Features::Command
        include Features::Input
        include Features::Trigger
      end
    end
  end
end
