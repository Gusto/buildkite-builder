Buildkite::Builder.pipeline do
  # Declare that we're using the Buildkite docker plugin.
  plugin :docker, "docker#v3.7.0"

  command do
    label emoji: :rspec
    command \
      "bundle",
      "rake"
    plugin :docker,
      image: "ruby:3.0"
  end

  trigger do
    label "Showcase", emoji: :buildkite
    trigger :showcase
    build \
      message: "${BUILDKITE_MESSAGE}",
      commit: "${BUILDKITE_COMMIT}",
      branch: "${BUILDKITE_BRANCH}"
  end
end
