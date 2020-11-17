Buildkite::Builder.pipeline do
  processors(
    Processors::PipelineSpecificProcessor,
    Processors::SharedProcessor
  )
  command(:basic)
end
