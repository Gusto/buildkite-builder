module Buildkite
  module Converter
    module StepAttributes
      autoload :Abstract, File.expand_path('step_attributes/abstract', __dir__)
      autoload :Label, File.expand_path('step_attributes/label', __dir__)
      autoload :Agents, File.expand_path('step_attributes/agents', __dir__)
      autoload :SimpleString, File.expand_path('step_attributes/simple_string', __dir__)
      autoload :Retry, File.expand_path('step_attributes/retry', __dir__)
      autoload :StringValue, File.expand_path('step_attributes/string_value', __dir__)
      autoload :Timeout, File.expand_path('step_attributes/timeout', __dir__)
      autoload :Wait, File.expand_path('step_attributes/wait', __dir__)
      autoload :Plugins, File.expand_path('step_attributes/plugins', __dir__)
      autoload :ArrayType, File.expand_path('step_attributes/array_type', __dir__)
      autoload :Env, File.expand_path('step_attributes/env', __dir__)
      autoload :Numeric, File.expand_path('step_attributes/numeric', __dir__)
      autoload :Boolean, File.expand_path('step_attributes/boolean', __dir__)
      autoload :Build, File.expand_path('step_attributes/build', __dir__)
      autoload :Condition, File.expand_path('step_attributes/condition', __dir__)
    end
  end
end
