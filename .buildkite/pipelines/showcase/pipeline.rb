Buildkite::Builder.pipeline do
  use(Buildkite::Builder::Extensions::Env)
  use(Buildkite::Builder::Extensions::Notify)
  use(Buildkite::Builder::Extensions::Steps)

  env(CI: '1')
  env(DEPLOYABLE: '1')
  notify(email: "dev@acmeinc.com")
  notify( basecamp_campfire: "https://3.basecamp.com/1234567/integrations/qwertyuiop/buckets/1234567/chats/1234567/lines")

  group do
    # Load the "rspec" template as a command.
    # .buildkite/pipelines/showcase/templates/rspec.rb
    command(:rspec)

    # Load the "rspec" template and modify it on the fly.
    command(:rspec) do
      label "RSpec relabeled"
      command "echo 'do something else'"
    end
  end

  # Pass arguments into templates.
  command(:generic, foo: 'Foo1')
  command(:generic, foo: 'Foo2')

  # Add complex conditions based on your cobebase as to whether or not a step
  # should be defined.
  if true == false
    command do
      label "This won't run"
      command 'true'
    end
  end

  # Add a wait step.
  wait

  # Add a skipped step. You can see this step when you click the "eye" icon on
  # the Buildkite web UI.
  command do
    command 'true'
    label "Skipped Step"

    # Conditionally skip a step.
    if true == true
      skip "This step is skipped because of x, y, and z"
    end
  end
end
