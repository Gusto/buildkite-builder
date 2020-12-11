Buildkite::Builder.pipeline do
  # Declare that we're using the Buildkite docker plugin.
  plugin :docker, "docker", "v3.7.0"

  command do
    label emoji: :rspec
    command \
      "bundle",
      "rake"
    plugin :docker,
      image: "ruby:latest"
  end
end
