Buildkite::Builder.pipeline do
  # Declare that we're using the Buildkite docker plugin.
  plugin :docker, "docker#v3.7.0"

  command do
    key :rspec
    label emoji: :rspec
    command \
      "bundle",
      "rake"
    plugin :docker,
      image: "ruby:3.3"
  end

  trigger do
    label "Showcase", emoji: :buildkite
    trigger :showcase
    build \
      message: "${BUILDKITE_MESSAGE}",
      commit: "${BUILDKITE_COMMIT}",
      branch: "${BUILDKITE_BRANCH}"
  end

  if Buildkite.env.default_branch?
    block do
      key :confirm_publish
      block ":rocket: Release to Docker Hub"
      prompt "Push release to Docker Hub?"
      depends_on :rspec
    end

    command do
      label emoji: :docker
      command "bin/release"
      depends_on :confirm_publish
    end
  end
end
