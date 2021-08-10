Buildkite::Builder.pipeline do
  use(Processors::Basic)
  command(:basic)
end
