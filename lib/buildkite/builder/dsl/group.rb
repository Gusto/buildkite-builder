module Buildkite
  module Builder
    module Dsl
      class Group < Abstract
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
