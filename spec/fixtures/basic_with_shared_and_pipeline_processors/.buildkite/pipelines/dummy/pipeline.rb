Buildkite::Builder.pipeline do
  use(Processors::PipelineSpecificProcessor)
  use(Processors::SharedProcessor)

  command(:basic)
end
