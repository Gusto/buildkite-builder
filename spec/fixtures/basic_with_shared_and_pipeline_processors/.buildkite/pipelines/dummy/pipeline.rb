Buildkite::Builder.pipeline do
  use(Processors::PipelineSpecificProcessor, foo: :bar)
  use(Processors::SharedProcessor)

  command(:basic)
end
