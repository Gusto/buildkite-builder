Buildkite::Builder.pipeline do
  command do
    label 'Simple step'
    command 'true'
  end
end
