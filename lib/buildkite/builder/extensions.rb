# frozen_string_literal: true

module Buildkite
  module Builder
    module Extensions
      autoload :Agents, File.expand_path('extensions/agents', __dir__)
      autoload :Env, File.expand_path('extensions/env', __dir__)
      autoload :Lib, File.expand_path('extensions/lib', __dir__)
      autoload :Notify, File.expand_path('extensions/notify', __dir__)
      autoload :Steps, File.expand_path('extensions/steps', __dir__)
      autoload :Plugins, File.expand_path('extensions/plugins', __dir__)
      autoload :Use, File.expand_path('extensions/use', __dir__)
    end
  end
end
