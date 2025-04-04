Buildkite::Builder.pipeline do
  # You can require files from the `.buildkite/lib` directory because it's
  # automatically added to the Ruby load path.
  require 'cool_lib'

  use(MyCoolExtension) do
    pipeline do
      command do
        label 'Appended Step'
        command 'echo 1'
      end
    end
  end
  use(ExtensionWithDsl)

  CoolLib.resolve(context.logger)

  env CI: "1"
  env DEPLOYABLE: "1"
  notify email: "dev@acmeinc.com"
  notify basecamp_campfire: "https://3.basecamp.com/1234567/integrations/qwertyuiop/buckets/1234567/chats/1234567/lines"

  # Register a plugin for steps to use.
  plugin :skip_checkout, 'thedyrt/skip-checkout#v0.1.1'

  command do
    label "Step w/ Plugin"
    key :step_with_plugin
    command "true"
    # Reference the plugin by its assigned name.
    plugin :skip_checkout
  end

  group do
    label "Cool Group", emoji: :partyparrot
    # Load the "rspec" template as a command.
    # .buildkite/pipelines/showcase/templates/rspec.rb
    command(:rspec)

    # Load the "rspec" template and modify it on the fly.
    command(:rspec) do
      label "RSpec relabeled"
      command "echo 'do something else'"
      plugin :skip_checkout
    end

    depends_on :step_with_plugin
    key :cool_group
  end

  component("Cool Component") do
    command(:generic, foo: "Bar")
  end

  # Pass arguments into templates.
  command(:generic, foo: "Foo1")
  command(:generic, foo: "Foo2")

  # Set a custom GitHub commit status.
  command(:generic, foo: "Baz") do
    notify github_commit_status: { context: "showcase/baz" }
  end

  # Add complex conditions based on your cobebase as to whether or not a step
  # should be defined.
  if true == false
    command do
      label "This won't run"
      command "true"
    end
  end

  # Add a wait step.
  wait

  # Add a skipped step. You can see this step when you click the "eye" icon on
  # the Buildkite web UI.
  command do
    command "true"
    label "Skipped Step"

    # Conditionally skip a step.
    if true == true
      skip "This step is skipped because of x, y, and z"
    end
  end
end
