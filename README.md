# Buildkite Builder [![Build status](https://badge.buildkite.com/a26bf804e9a93fb118d29824d5695a601a248ceec51591be23.svg?branch=main)](https://buildkite.com/gusto-open-source/buildkite-builder/builds?branch=main)

## Introduction
Buildkite Builder (BKB) is a Buildkite pipeline builder written in Ruby. It allows you to build your pipeline with a Ruby DSL for dynamically generated pipeline steps.

## Gem Installation (optional)

There are 2 components to this toolkit. The `buildkite-builder` Rubygem and the `buildkite-builder` Docker image. You technically only need the image to use Buildkite Builder, but installing the gem in your repo helps you preview your pipeline during development.

To install the gem, add this line to your application's Gemfile:

```ruby
gem 'buildkite-builder'
```

The gem provides a command line tool that lets you perform various operations on your pipelines:

```shell
  $ buildkite-builder help
```

## Pipeline Installation

As with every Buildkite pipeline, you'll need to define the initial pipeline step. You can do this directly in the Pipeline Settings or with a `.buildkite/pipeline.yml` file in your repository. You'll need to define a single step to kick off Buildkite Builder:

```yaml
steps:
  - label: ":toolbox:"
    plugins:
      - docker#v3.7.0:
          image: gusto/buildkite-builder:1.1.0
          propagate-environment: true
```

Some things to note:
  - The `label` can be whatever you like.
  - You'll want to update the `docker` plugin version from time to time.
  - You can update the `buildkite-builder` version by bumping the Docker image tag.

## Usage

💡 We have a [Showcase pipeline](https://buildkite.com/gusto-open-source/showcase/builds/latest?branch=main) (defined in [`.buildkite/pipelines/showcase/pipeline.rb`](https://github.com/Gusto/buildkite-builder/blob/main/.buildkite/pipelines/showcase/pipeline.rb)) that, well, showcases some of the features and possibilities with Buildkite Builder. Sometimes the best way to learning something is seeing how it's used.

At its core, BKB is really just a YAML builder. This tool allows you to scale your needs when it comes to building a Buildkite pipeline. Your pipeline can be as straight forward as you'd like, or as complex as you need. Since you have Ruby at your disposal, you can do some cool things like:
  - Perform pre-build code/diff analysis to determine whether or not to to add a step to the pipeline.
  - Reorder pipeline steps dynamically.
  - Augment your pipeline steps with BKB processors.
  
### Pipeline Files
Your repo can contain as many pipeline definitions as you'd like. By convention, pipeline file structure are as such:

```
.buildkite/
  pipelines/
    <your-pipeline1-slug>/
      pipeline.rb
    <your-pipeline2-slug>/
      pipeline.rb
```

For an example, refer to the [dummy pipeline in the fixtures directory](https://github.com/Gusto/buildkite-builder/blob/main/spec/fixtures/basic/.buildkite/pipelines/dummy/pipeline.rb).

### Defining Steps

Buildkite Builder was designed to be as intuitive as possible by making DSL match Buildkite's attributes and [step types](https://buildkite.com/docs/pipelines/defining-steps#step-types). Here's a basic pipeline:

```ruby
Buildkite::Builder.pipeline do
  command do
    label "Rspec", emoji: :rspec
    command "bundle exec rspec"
  end
  
  wait
  
  trigger do
    trigger "deploy-pipeline"
  end
end
```

Which generates:

```yaml
steps:
  - label: ":rspec: RSpec"
    command: "bundle exec rspec"
  - wait
  - trigger: deploy-pipeline
```

If the step type or attribute exists in Buildkite docs, then it should exist in the DSL. **The only exception is the `if` attribute**. Since `if` is a ruby keyword, we've mapped it to `condition`.

### Step Templates

If your pipeline has a lot of steps, you should consider using Step Templates. Templates allow you to break out your build steps into reusable template files.

```
.buildkite/
  pipelines/
    foobar-widget/
      pipeline.rb
      templates/
        rspec.rb
        rubocop.rb
```

A template is basically a step that was extracted from the pipeline:

`.buildkite/pipelines/foobar-widget/templates/rspec.rb`
```ruby
Buildkite::Builder.template do
  label "Rspec", emoji: :rspec
  commmand "bundle exec rspec"
end
```

You can then include the template into the the pipeline once or as many time as you need. The template name will be the name of the file (without the extension).

`.buildkite/pipelines/foobar-widget/pipeline.rb`
```ruby
Buildkite::Builder.pipeline do
  command(:rspec)
  
  # Reuse and agument templates on the fly.
  command(:rspec) do
    label "Run RSpec again!"
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gusto/buildkite-builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/gusto/buildkite-builder/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Buildkite::Builder project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/gusto/buildkite-builder/blob/main/CODE_OF_CONDUCT.md).
