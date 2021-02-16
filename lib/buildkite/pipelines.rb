# frozen_string_literal: true

module Buildkite
  module Pipelines
    autoload :Api, File.expand_path('pipelines/api', __dir__)
    autoload :Attributes, File.expand_path('pipelines/attributes', __dir__)
    autoload :Command, File.expand_path('pipelines/command', __dir__)
    autoload :Helpers, File.expand_path('pipelines/helpers', __dir__)
    autoload :Pipeline, File.expand_path('pipelines/pipeline', __dir__)
    autoload :Plugin, File.expand_path('pipelines/plugin', __dir__)
    autoload :StepContext, File.expand_path('pipelines/step_context', __dir__)
    autoload :Steps, File.expand_path('pipelines/steps', __dir__)
  end
end
