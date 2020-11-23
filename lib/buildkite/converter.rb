module Buildkite
  module Converter
    autoload :PipelineYml, File.expand_path('converter/pipeline_yml', __dir__)
    autoload :AttributeParser, File.expand_path('converter/attribute_parser', __dir__)
    autoload :StepAttributes, File.expand_path('converter/step_attributes', __dir__)
    autoload :PluginsStore, File.expand_path('converter/plugins_store', __dir__)
    autoload :PipelineStep, File.expand_path('converter/pipeline_step', __dir__)
    autoload :Generator, File.expand_path('converter/generator', __dir__)
  end
end
