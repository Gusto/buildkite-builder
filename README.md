# Buildkite::Builder

## Introduction
Buildkite Builder provides a DSL to make it easier to build pipelines for Buildkite. It lets you specify how to build pipelines using Ruby instead of having a complicated YAML file.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'buildkite-builder'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install buildkite-builder

Then access the commands:

    $ buildkite-builder

## Usage

### Replacing `pipeline.yml`
At it's core, Buildkite Builder generates a YAML file that it uploads to Buildkite, that takes the place of the pipeline file that Buildkite expects in `.buildkite/pipeline.yml`.

Make a new `.buildkite/pipeline.yml` and replace it with:
```yaml
# DO NOT MODIFY THIS FILE.
#
# This is the Buildkite Builder bootstrap step for all projects.
#
# If you're looking for your project's actual pipeline, look in:
# .buildkite/pipelines/{PIPELINE_SLUG}/pipeline.rb

steps:
  - label: ":toolbox:"
    key: "buildkite-builder"
    retry:
      automatic:
        - exit_status: -1   # Agent was lost
          limit: 2
        - exit_status: 255  # Forced agent shutdown
          limit: 2
    plugins:
      - docker#v3.7.0:
          image: "gusto/buildkite-builder:1.0.0"
          always-pull: true
          propagate-environment: true
          environment:
            - "GITHUB_API_TOKEN"
            - "BUILDKITE_API_TOKEN"
```

### Creating a Buildkite Builder `pipeline.rb`
Create a new directory for your pipeline in `.buildkite/pipelines/<your-pipeline-slug>/pipeline.rb`. 

For an example, refer to the [dummy pipeline in the fixtures directory](https://github.com/Gusto/buildkite-builder/blob/main/spec/fixtures/basic/.buildkite/pipelines/dummy/pipeline.rb).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gusto/buildkite-builder. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/gusto/buildkite-builder/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Buildkite::Builder project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/gusto/buildkite-builder/blob/main/CODE_OF_CONDUCT.md).
