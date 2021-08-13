# frozen_string_literal: true

module Buildkite
  module Builder
    module Extensions
      autoload :Env, File.expand_path('extensions/env', __dir__)
      autoload :Notify, File.expand_path('extensions/notify', __dir__)
      autoload :Steps, File.expand_path('extensions/steps', __dir__)
    end
  end
end
