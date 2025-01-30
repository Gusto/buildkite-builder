# frozen_string_literal: true

module Buildkite
  module Pipelines
    module Steps
      autoload :Abstract, File.expand_path('steps/abstract', __dir__)
      autoload :Block, File.expand_path('steps/block', __dir__)
      autoload :Command, File.expand_path('steps/command', __dir__)
      autoload :Group, File.expand_path('steps/group', __dir__)
      autoload :Input, File.expand_path('steps/input', __dir__)
      autoload :Trigger, File.expand_path('steps/trigger', __dir__)
      autoload :Wait, File.expand_path('steps/wait', __dir__)
    end
  end
end
