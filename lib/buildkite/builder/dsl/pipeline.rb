module Buildkite
  module Builder
    module Dsl
      class Pipeline < Abstract
        include Features::Env
        include Features::Notify
        include Features::Skip
        include Features::Wait
        include Features::Block
        include Features::Command
        include Features::Group
        include Features::Input
        include Features::Template
        include Features::Trigger
      end
    end
  end
end
