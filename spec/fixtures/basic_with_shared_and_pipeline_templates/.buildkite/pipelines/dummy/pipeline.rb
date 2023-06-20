Buildkite::Builder.pipeline do
  use(Extensions::PipelineSpecificExtension, foo: :bar)
  use(Extensions::SharedExtension)

  command(:basic)
end
