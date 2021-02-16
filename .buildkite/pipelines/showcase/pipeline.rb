Buildkite::Builder.pipeline do
  # Load the "rspec" template as a command.
  # .buildkite/pipelines/showcase/templates/rspec.rb
  command(:rspec)

  # Load the "rspec" template and modify it on the fly.
  command(:rspec) do
    label "RSpec relabeled"
    command "echo 'do something else'"
  end

  # Pass arguments into templates.
  command(:generic, foo: 'Foo1')
  command(:generic, foo: 'Foo2')

  # Add complex conditions based on your cobebase as to whether or not a step
  # should be defined.
  if true == false
    command do
      label "This won't run"
      command :noop
    end
  end

  # Add a wait step.
  wait

  # Add a skipped step. You can see this step when you click the "eye" icon on
  # the Buildkite web UI.
  command do
    command :noop
    label "Skipped Step"

    # Conditionally skip a step.
    if true == true
      skip "This step is skipped because of x, y, and z"
    end
  end
end
