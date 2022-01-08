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
