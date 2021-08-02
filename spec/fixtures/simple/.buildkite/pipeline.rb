Buildkite::Builder.pipeline do
  command do
    label 'Simple step'
    command :noop
  end
end
