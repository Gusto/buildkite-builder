Buildkite::Builder.pipeline do
  # Load the "rspec" template as a command.
  command(:rspec)

  # Load the "rspec" template and modify it on the fly.
  command(:rspec) do
    label "RSpec relabeled"
    command "echo 'do something else'"
  end
end
