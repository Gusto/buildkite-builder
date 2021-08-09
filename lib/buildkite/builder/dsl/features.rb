# frozen_string_literal: true

module Buildkite
  module Builder
    module DSL
      module Features
        autoload :Env, File.expand_path('features/env', __dir__)
        autoload :Block, File.expand_path('features/block', __dir__)
        autoload :Command, File.expand_path('features/command', __dir__)
        autoload :Input, File.expand_path('features/input', __dir__)
        autoload :Notify, File.expand_path('features/notify', __dir__)
        autoload :Skip, File.expand_path('features/skip', __dir__)
        autoload :Trigger, File.expand_path('features/trigger', __dir__)
        autoload :Wait, File.expand_path('features/wait', __dir__)
      end
    end
  end
end
