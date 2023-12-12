### 4.6.0
* Remove `capture` concept on `Buildkite::Pipelines::Command#run` and replaced with `Buildkite::Pipelines::Command::Result` object to represent `Open3.capture3` result.

### 4.5.0
* Do not upload `pipeline.yml` when steps is empty.

### 4.4.0
* Fix multiple arguments for `depends_on`.

### 4.3.0
* Remove the `DependsOn` helper module since it doesn't do anything additive.

### 4.2.5
* Add `skip` attributes to Block and Input steps.

### 4.2.4
* Add more group step attributes as listed in https://buildkite.com/docs/pipelines/group-step#group-step-attributes

### 4.2.3
* Simplify pipeline upload duplication check

### 4.2.2
* Use step id to distinguish different piplelines, fix re-uploading pipeline on same step issue.

### 4.2.1
* Allow uploading pipeline to different jobs

### 4.2.0
* Add shared global templates

### 4.1.2
* Raise error with stderr/stdout message when `buildkite-agent` command failed while using bang commands (`artifact!`, `annotate!`, `pipeline!`, and `meta_data!`)
* Add `signal_reason` as an automatic retry option

### 4.1.1
* Fix `PluginManager`'s error message when plugin was not registered

### 4.1.0
* Remove `skip` step since it's only mimicing `command` step with a skip.

### 4.0.0
* Remove `subpipeline` since it's not a Buildkite standard.
* Refactor template handling
* Simplify `group` step implementation

### 3.9.0
* Create a `Plugins` extension to take care named plugins from the plugin manager.

### 3.8.1...3.8.3
* Expose extension manager to be accessible in dsl
* Removes an extra definition of `attr_reader :extensions` in pipeline
* Allow `group` steps to be able to use extension's dsl methods
* Show buildkite builder version at the beginning of the command

### 3.8.0
* Extensions can now take block as argument [example](https://github.com/Gusto/buildkite-builder/blob/v3.8.0/.buildkite/pipelines/showcase/pipeline.rb#L6-L13)

## 3.6.0
* `Buildkite::Pipelines::Command#run` now uses `Open3.capture3` to run system commands, and accepts an optional arg `capture`. When `capture` is true, it returns the stdout of the command. `capture` is true for the meta_data subcommands `get` and `keys` and for the artifact subcommands `shasum` and `search`.

## 3.5.0
* `plugin` registrations now takes an optional default attributes hash as the third argument.

## 3.4.1
* `automatic_retry_on` now overwrites rules with the same exit status.

## 3.4.0
* `automatically_retry(status:, limit:)` has been renamed to `automatic_retry_on(exit_status:, limit:)`
* Added `automatic_retry` for setting boolean for `retry.automatic`
* Added `manual_retry` for setting `retry.manual`

## 3.3.2
* Fix subpipeline trigger step attributes leak to subpipeline.

## 3.3.1
* Add support to iterate over subpipelines.
* Allow build options to be passed to subpipelines.

## 3.3.0
* Remove arguments in sub-pipeline's trigger step setup and use dsl delegation instead.

## 3.2.0
* Remove `template` from sub-pipeline trigger step setup and use arguments instead.

## 3.1.0
* Add subpipeline support to save triggered pipeline's YML definition beforehand to artifacts and pass down the file to an ENV for pipeline setup.

## 3.0.0
* Remove manifest features to prevent Github API dependency and simplify the gem to focus on Buildkite features.

## 2.4.1
* Fix pipeline upload as artifact logic.

## 2.4.0
* Upload custom pipeline artifacts in a single command.
* Only upload the pipeline as an artifact when the pipeline upload fails.

## 2.3.0
* Improve BKB step idempotency.

## 2.2.0
* Add `.buildkite/lib` directory to $LOAD_PATH if it exists.

## 2.1.0
* Fix a bug introduced in 2.0.0 where artifacts were being uploaded before extensions had a chance to do work.
* Remove `SortedSet` dependency.
* Add `annotate` pipeline command helper.
* Add `StepCollection#find` and `StepCollection#find!` for ease of finding a step by its key in extensions.
* `group` now supports the `emoji:` helper. (Eg. `group "foobar", emoji: :smile`)

## 2.0.0
* Add support for `group`.
* `Processor`s has been renamed to `Extension`. Extensions add more capabilities (will document separately).
* `plugin` no longer takes 2 arguments (source, version). It's simply 1 arg that is both source and version, separated by a `#`. This is more akin to Buildkite's usage.
* Full refactor of pipeline code allowing for extensions to extend DSL methods.

## 1.5.0
* Merge `BuildKite::Builder::Context` and `BuildKite::Pipelines::Pipeline` to `BuildKite::Builder::Pipeline` (#37)

## 1.4.1
* Fix the Github API Builder to account for Buildkite having both `.git` and no file exention repository URIs (#33)

## 1.4.0
* Fix the `files` command. You now pass in the manifest with the `--manifest` CLI argument.

## 1.3.1
* Expose `data` from `StepContext` to `Step`

## 1.3.0
* Add ability for step to store data in step context
* Move `upload` from `BuildKite::Builder::Commands::Run` to `BuildKite::Builder::Context`
* Add ability to set custom artifacts in context and uplaod before `pipeile upload`
