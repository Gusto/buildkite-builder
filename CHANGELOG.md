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
