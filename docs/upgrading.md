# Upgrading buildkite-builder

This guide covers how to upgrade between major versions of buildkite-builder, and how to stay current on the latest 4.x releases.

## What Version Am I On?

**From your Gemfile.lock:**

```
grep "buildkite-builder" Gemfile.lock
```

Look for `buildkite-builder (X.Y.Z)` in the output.

**From the gem itself:**

```ruby
Buildkite::Builder.version
```

**From the Docker image tag:**

If you're using the `gusto/buildkite-builder` Docker image, the tag is your version (e.g., `gusto/buildkite-builder:4.13.0`).

## Upgrade Paths

### 1.x to 2.x

<!-- TODO: High-level upgrade path for 1.x to 2.x. Cover what changed, why you'd upgrade, and the key steps. Reference the Detailed Change Reference for specifics. -->

### 2.x to 3.x

<!-- TODO: High-level upgrade path for 2.x to 3.x. Cover what changed, why you'd upgrade, and the key steps. Reference the Detailed Change Reference for specifics. -->

### 3.x to 4.x

<!-- TODO: High-level upgrade path for 3.x to 4.x. Cover what changed, why you'd upgrade, and the key steps. Reference the Detailed Change Reference for specifics. -->

### Staying Current on 4.x

<!-- TODO: What to watch for in 4.x minor releases. Any deprecations, feature additions, or behavioral changes worth calling out. -->

## Detailed Change Reference

### 2.0.0

The 2.0.0 release was the largest breaking change in buildkite-builder's history. The internal architecture was reorganized around Extensions, a new DSL system, and file-based templates. Almost every consumer-facing API changed.

#### Processor to Extension Rename

**What changed:** `Buildkite::Builder::Processors::Abstract` was removed. The replacement is `Buildkite::Builder::Extension`, a more capable base class with lifecycle hooks, DSL extensibility, and block configuration.
**Why:** Processors were limited to a single class method (`self.process(pipeline)`) that ran after the pipeline was fully built. Extensions participate in the build lifecycle with `prepare` (before pipeline evaluation) and `build` (after), can define custom DSL methods, and accept configuration options. This enabled features like `group`, `env`, and `notify` to be implemented as extensions rather than hardcoded into the pipeline class.

Before:

```ruby
# .buildkite/processors/my_processor.rb
class MyProcessor < Buildkite::Builder::Processors::Abstract
  def process
    pipeline_steps(:command).each do |step|
      step.label("#{step.label} (modified)")
    end
  end
end
```

After:

```ruby
# .buildkite/extensions/my_extension.rb (note: directory renamed too)
class MyExtension < Buildkite::Builder::Extension
  def prepare
    # Runs before the pipeline block is evaluated.
    # Set up data, register resources, etc.
  end

  def build
    # Runs after the pipeline block is evaluated.
    # Modify steps, add computed steps, etc.
    pipeline do
      command do
        label "Appended by extension"
        command "echo 1"
      end
    end
  end

  # Optional: define DSL methods available in the pipeline block.
  dsl do
    def component(name, &block)
      group("Component: #{name}", &block)
    end
  end
end
```

**Migration:**
1. Rename your `.buildkite/processors/` directory to `.buildkite/extensions/` (both global and per-pipeline).
2. Change each class to inherit from `Buildkite::Builder::Extension` instead of `Buildkite::Builder::Processors::Abstract`.
3. Rename `def process` to `def build`. The method is now an instance method, not called via `self.process(pipeline)`.
4. Replace `pipeline_steps(:command)` with direct pipeline access through `pipeline { ... }` or `context.data.steps.each(:command)`.
5. If your processor accessed `pipeline.steps` directly, see the "steps accessor" entry below.

**Verification:** Run `buildkite-builder preview <pipeline>` and confirm your extensions appear in the log output under "Processing <ExtensionName>".
**Risk:** High. Every custom processor must be rewritten. The class hierarchy, method signatures, and lifecycle are all different.

---

#### Plugin API Change

**What changed:** The `plugin` registration DSL changed from three arguments to two. The version is now part of the URI string, separated by `#`.
**Why:** This matches Buildkite's own plugin syntax, where plugins are referenced as `org/plugin#version`. Having version as a separate argument was a buildkite-builder-specific convention that didn't match the ecosystem.

Before:

```ruby
plugin :docker, 'docker-compose', 'v3.7.0'
```

After:

```ruby
plugin :docker, 'docker-compose#v3.7.0'
```

**Migration:** In your pipeline files, merge the second and third arguments of every `plugin` call into a single `'source#version'` string.
**Verification:** Run `buildkite-builder preview <pipeline>` and confirm plugins appear correctly in the YAML output with the expected versions.
**Risk:** Medium. Straightforward find-and-replace, but every plugin registration must be updated.

---

#### Pipeline Construction Change

**What changed:** `Pipeline.build(root)` was removed. Pipeline definition now uses `Buildkite::Builder.pipeline { ... }` with a block evaluated on a `Dsl` object. Internally, `Pipeline.new(root)` still exists but the build happens lazily in `to_h`/`to_yaml`.
**Why:** The old `Pipeline` class was a monolith that held steps, templates, plugins, env, notify, and processors all in one object. The refactor split responsibilities: `Data` holds pipeline data, `Dsl` handles the evaluation context, `ExtensionManager` manages extensions, and `StepCollection`/`TemplateManager`/`PluginManager` each handle their domain. This made it possible for extensions to add DSL methods and for groups to share the same step-building interface.

Before:

```ruby
# pipeline.rb was instance_eval'd on the Pipeline object itself
Buildkite::Builder.pipeline do
  # `self` here was the Pipeline instance
  # Steps, plugins, templates, env, notify all lived on Pipeline
  command(:my_template)
  plugin :docker, 'docker-compose', 'v3.7.0'
  template(:custom) { label "inline" }
end
```

After:

```ruby
# pipeline.rb is instance_eval'd on a Dsl object
Buildkite::Builder.pipeline do
  # `self` here is a Dsl instance, extended with Extension DSL modules
  # Steps, plugins, etc. are managed by their respective extensions
  use(MyExtension)
  command(:my_template)
  plugin :docker, 'docker-compose#v3.7.0'
end
```

**Migration:**
1. Pipeline files (`pipeline.rb`) should still use `Buildkite::Builder.pipeline do ... end`. The block syntax is the same, but the receiver changed.
2. Remove any `Pipeline.build(root)` calls in custom tooling. Use `Pipeline.new(root).to_yaml` instead.
3. Remove inline `template(:name) { ... }` calls from pipeline files (see Template System Change below).
4. Remove `processors(...)` calls from pipeline files (see Processor to Extension Rename above).

**Verification:** Run `buildkite-builder preview <pipeline>` and compare output to your previous pipeline YAML.
**Risk:** High. The internal model changed significantly. If you only use the standard DSL (`command`, `wait`, `block`, etc.), the migration is mostly transparent. If you accessed `Pipeline` internals, expect breakage.

---

#### Template System Change

**What changed:** Inline templates defined via `pipeline.template(:name) { ... }` were removed. Templates are now auto-loaded from the `templates/` directory by `TemplateManager`.
**Why:** Inline templates cluttered pipeline files and couldn't be reused across pipelines. File-based templates were already supported in 1.x (the `templates/` directory existed), but you could also define them inline. 2.0 made file-based the only option, simplifying the template resolution path.

Before:

```ruby
# Inline template definition in pipeline.rb
Buildkite::Builder.pipeline do
  template(:rspec) do
    label "RSpec"
    command "bundle exec rspec"
  end

  command(:rspec)
end
```

After:

```ruby
# .buildkite/pipelines/<name>/templates/rspec.rb
label "RSpec"
command "bundle exec rspec"
```

```ruby
# pipeline.rb (templates auto-loaded from templates/ directory)
Buildkite::Builder.pipeline do
  command(:rspec)
end
```

**Migration:**
1. For each inline `template(:name) { ... }` block, create a corresponding file at `.buildkite/pipelines/<pipeline>/templates/<name>.rb`.
2. Move the block body into the template file.
3. Remove the `template(...)` calls from `pipeline.rb`.

**Verification:** Run `buildkite-builder preview <pipeline>` and confirm template-based steps render the same YAML as before.
**Risk:** High if you relied on inline templates. Low if you were already using file-based templates (no change needed).

---

#### Group Support (New Feature)

**What changed:** Added `group("label") { ... }` DSL method for organizing steps into collapsible groups in the Buildkite UI.
**Why:** Buildkite supports group steps natively, but buildkite-builder had no way to express them. Groups make large pipelines more readable in the Buildkite dashboard.

```ruby
Buildkite::Builder.pipeline do
  group("Tests") do
    command(:rspec)
    command(:jest)
    depends_on :setup
    key :tests
  end

  group("Deploy") do
    command(:deploy)
    depends_on :tests
  end
end
```

Groups support `depends_on`, `key`, `notify`, and all step-building DSL methods (`command`, `block`, `wait`, etc.). Groups cannot be nested.

**Migration:** No migration needed. This is additive.
**Verification:** Run `buildkite-builder preview <pipeline>` and confirm groups appear in the YAML output with the `group` key.
**Risk:** Low. New feature, no breaking changes.

---

#### use() DSL (New Feature)

**What changed:** Added `use(ExtensionClass)` DSL method to register extensions from within a pipeline definition.
**Why:** In 1.x, processors were auto-loaded from the `processors/` directory and configured via `processors(MyProcessor)` in the pipeline. The `use` pattern is more explicit, supports passing options to extensions, and makes it clear which extensions a pipeline depends on.

```ruby
Buildkite::Builder.pipeline do
  use(MyExtension)
  use(AnotherExtension, some_option: "value")

  command(:rspec)
end
```

**Migration:** Replace `processors(ProcessorA, ProcessorB)` with individual `use(ExtensionA)` and `use(ExtensionB)` calls.
**Verification:** Run `buildkite-builder preview <pipeline>` and confirm extensions are invoked (they appear in log output).
**Risk:** Low. New feature, but replaces the old `processors(...)` registration which was removed.

---

#### steps Accessor Removed

**What changed:** `pipeline.steps` (which returned an Array) was removed. Steps are now accessed through `pipeline.data.steps`, which returns a `StepCollection` instance.
**Why:** Moving steps into a `StepCollection` on `Data` was part of the larger decomposition of the `Pipeline` monolith. `StepCollection` provides typed iteration (`each(:command)`), template/plugin awareness, and group traversal. Storing it on `Data` means extensions access steps the same way regardless of context (pipeline or group).

Before:

```ruby
# In a processor
def process
  pipeline.steps.each do |step|
    # step manipulation
  end
end
```

After:

```ruby
# In an extension
def build
  context.data.steps.each do |step|
    # step manipulation
  end

  # Filter by step type
  context.data.steps.each(:command) do |step|
    # only command steps (traverses into groups automatically)
  end
end
```

**Migration:** Replace `pipeline.steps` with `context.data.steps` in extensions. Use `each(:command)` for type-filtered iteration.
**Verification:** Confirm your extension builds without `NoMethodError` and steps are correctly modified.
**Risk:** Medium. Any code that accessed `pipeline.steps` directly needs updating.

---

#### StepCollection Methods (2.1.0)

**What changed:** `StepCollection` gained `find(key)` and `find!(key)` methods for locating steps by their key attribute.
**Why:** Extensions frequently need to find and modify specific steps. Without `find`, you had to iterate manually and match on keys yourself.

```ruby
# In an extension
def build
  step = context.data.steps.find!(:rspec)
  pipeline do
    # modify or reference the found step
  end
end
```

`find` returns `nil` if no step matches. `find!` raises `ArgumentError`.

**Migration:** No migration needed. This is additive (shipped in 2.1.0).
**Verification:** N/A.
**Risk:** Low. New convenience methods.

---

#### annotate Command Helper (2.1.0)

**What changed:** Added `Buildkite::Pipelines::Command.annotate` and `annotate!` class methods for creating Buildkite annotations from within extensions.
**Why:** Annotations are a common Buildkite feature. Having a dedicated helper avoids manual `buildkite-agent annotate` shell calls.

```ruby
Buildkite::Pipelines::Command.annotate("Build passed!", "--style", "success")
Buildkite::Pipelines::Command.annotate!("Critical note", "--style", "error")  # aborts on failure
```

**Migration:** No migration needed. This is additive (shipped in 2.1.0).
**Verification:** N/A.
**Risk:** Low. New convenience method.

---

#### SortedSet Dependency Removed (2.1.0)

**What changed:** The `SortedSet` dependency was removed from the gem.
**Why:** Ruby 3.x moved `SortedSet` out of the standard library into a separate gem (`sorted_set`). Removing the dependency avoided forcing consumers to add `sorted_set` to their Gemfile when upgrading Ruby.

**Migration:** No migration needed. If you depended on `SortedSet` being available transitively through buildkite-builder, add `sorted_set` to your own Gemfile.
**Verification:** Run `bundle install` and confirm no missing dependency errors.
**Risk:** Low. Only affects you if you relied on the transitive dependency.

### 3.0.0

The 3.0.0 release had a single focused breaking change: removing the manifest system and its GitHub API dependency. If you never used manifests for conditional pipeline steps, there is nothing to migrate.

#### Manifest System Removed

**What changed:** `Buildkite::Builder::Manifest`, `Buildkite::Builder::Manifest::Rule`, `Buildkite::Builder::FileResolver`, `Buildkite::Builder::Github`, and the `buildkite-builder files` CLI command were all removed. The `manifests/` directory is no longer loaded.
**Why:** The manifest system required a GitHub API token to resolve changed files in pull requests. This created an external dependency that complicated gem setup, was fragile in non-GitHub environments, and was outside the scope of what buildkite-builder should do. Buildkite's own trigger steps and pipeline upload logic can handle conditional builds without a separate file-resolution layer.

Before:

```ruby
# .buildkite/manifests/backend.txt
lib/
app/
spec/

# In a pipeline or extension
if Buildkite::Builder::Manifest.resolve(Buildkite::Builder.root, ['lib/', 'app/'])
  command(:run_tests)
end

# Or using a named manifest loaded from .buildkite/manifests/
if Buildkite::Builder::Manifest[:backend].modified?
  command(:backend_tests)
end
```

After:

```ruby
# No direct equivalent in buildkite-builder. Options:
#
# 1. Use Buildkite's built-in `if:` condition on steps (runs at agent level):
#    https://buildkite.com/docs/pipelines/conditionals
#
# 2. Use a trigger step pattern where each pipeline uploads itself conditionally.
#
# 3. Use a shell script in your pipeline.rb that runs git diff manually
#    and gates which steps are added.
```

**Migration:**
1. Delete your `.buildkite/manifests/` directory.
2. Remove any `Manifest.resolve(...)`, `Manifest[:name].modified?`, or `Manifest[:name].files` calls.
3. Remove `GITHUB_API_TOKEN` from your Buildkite environment variables if it was only there for buildkite-builder.
4. Replace conditional step logic with one of the alternatives above. The Buildkite `if:` condition is the closest native equivalent for per-step file-based conditions.

**Verification:** Run `bundle exec buildkite-builder preview <pipeline>` and confirm no `NameError: uninitialized constant Buildkite::Builder::Manifest` errors. Remove the `files` subcommand from any scripts that called `buildkite-builder files --manifest <name>`.
**Risk:** High if you used manifests for conditional steps. None if you didn't.

---

#### Retry DSL Renamed (3.4.0)

**What changed:** `automatically_retry(status:, limit:)` was renamed to `automatic_retry_on(exit_status:, limit:)`. Two new methods were added: `automatic_retry(enabled)` for toggling the boolean form of `retry.automatic`, and `manual_retry(allowed, reason:, permit_on_passed:)` for configuring manual retry behavior.
**Why:** The renamed keyword argument `exit_status:` is more explicit than `status:`, and the new `automatic_retry` and `manual_retry` methods cover the full Buildkite retry API that was previously inaccessible.

Before:

```ruby
command do
  label "Tests"
  command "bundle exec rspec"
  automatically_retry(status: -1, limit: 2)
end
```

After:

```ruby
command do
  label "Tests"
  command "bundle exec rspec"
  automatic_retry_on(exit_status: -1, limit: 2)

  # Also available:
  manual_retry(true, reason: "Flaky test", permit_on_passed: false)
end
```

**Migration:** Rename `automatically_retry(status: ...)` to `automatic_retry_on(exit_status: ...)`. Update both the method name and the keyword argument name.
**Verification:** Run `buildkite-builder preview <pipeline>` and confirm retry rules appear under `retry.automatic` in the YAML output.
**Risk:** Medium. Straightforward rename, but every use of `automatically_retry` must be updated.

---

#### Plugin Default Attributes (3.5.0)

**What changed:** The `plugin` registration DSL now accepts an optional third argument: a hash of default attributes that will be merged into every use of that plugin.
**Why:** Many plugins have boilerplate configuration that's the same across every step (e.g., a Docker image, a registry URL). Without defaults, you had to repeat the attributes on every step. With defaults, you register them once and override per-step only when needed.

Before:

```ruby
# Registration (no default attributes)
plugin :docker, 'docker-compose#v3.7.0'

# Usage: had to pass attributes every time
command do
  plugin :docker, image: 'ruby:3.2'
end
```

After:

```ruby
# Registration with defaults
plugin :docker, 'docker-compose#v3.7.0', image: 'ruby:3.2', pull: true

# Usage: defaults are merged in automatically
command do
  plugin :docker  # uses image: 'ruby:3.2', pull: true
end

command do
  plugin :docker, image: 'ruby:3.3'  # overrides the default image
end
```

**Migration:** No migration needed unless you want to adopt defaults. The third argument is optional, so existing registrations continue to work without changes.
**Verification:** Run `buildkite-builder preview <pipeline>` and confirm plugin attributes appear correctly in the YAML output.
**Risk:** Low. Additive change.

---

#### Extension Block Arguments (3.8.0)

**What changed:** Extensions and the `use` DSL method now accept a block argument, available to the extension as `option_block`.
**Why:** Some extension configurations are more naturally expressed as blocks than as keyword argument hashes. This gives extension authors a way to accept block-based configuration (e.g., for DSL-style setup that would be awkward as options).

Before:

```ruby
# Only keyword args were supported
use(MyExtension, option: "value")
```

After:

```ruby
# Block argument now available in addition to keyword args
use(MyExtension, option: "value") do
  # Block is available inside the extension as `option_block`
end

# Inside your extension:
class MyExtension < Buildkite::Builder::Extension
  def prepare
    option_block&.call  # Execute the block if provided
  end
end
```

**Migration:** No migration needed. Existing extensions that don't use `option_block` are unaffected.
**Verification:** N/A unless you're authoring an extension that uses this feature.
**Risk:** Low. Additive change.

---

#### Plugins Extension and Named Plugin Registry (3.9.0)

**What changed:** A new `Extensions::Plugins` extension was added to manage the named plugin registry. Previously, `plugin :name, 'uri#version'` registrations were handled by the `Steps` extension. The `Plugins` extension takes over that responsibility and makes `context.extensions.find(Buildkite::Builder::Extensions::Plugins).manager` accessible for inspection.
**Why:** Separating plugin registry management from step building gives extensions a clean interface to access the plugin manager directly, without going through the pipeline context.

```ruby
# Registration unchanged -- this still works the same way
plugin :docker, 'docker-compose#v3.7.0'

# In an extension that needs to inspect the plugin registry:
class MyExtension < Buildkite::Builder::Extension
  def build
    plugin_manager = context.extensions.find(Buildkite::Builder::Extensions::Plugins).manager
    # Inspect or use the manager
  end
end
```

**Migration:** No migration needed for pipeline files. Plugin registration and usage syntax is unchanged.
**Verification:** Run `buildkite-builder preview <pipeline>` and confirm plugins still appear in the YAML output.
**Risk:** Low. Internal refactor with a new public accessor.

### 4.0.0

The 4.0.0 release cleaned up three areas that had accumulated awkwardness: group steps got a proper implementation as first-class step types, sub-pipelines (added in 3.1.0) were removed, and template handling was refactored to live in `Extensions::Steps` instead of `StepCollection`. Ruby >= 3.0.0 is also required starting with this version.

#### Ruby 3.0.0 Required

**What changed:** The minimum required Ruby version is now 3.0.0 (up from 2.3.0 in 3.x).
**Why:** Ruby 2.x reached end-of-life. Requiring 3.0+ allows the gem to use modern Ruby features and drop compatibility shims.

**Migration:** Ensure your build environment runs Ruby >= 3.0.0. If you're using the `gusto/buildkite-builder` Docker image, upgrading to the 4.x tag handles this automatically.
**Verification:** Run `ruby --version` in your pipeline environment and confirm it's >= 3.0.0.
**Risk:** Low if you're already on Ruby 3.x. Medium if you're still on 2.x and need to upgrade your runtime.

---

#### Group DSL Change

**What changed:** The `group` DSL method no longer accepts a label or `emoji:` as arguments. Label and emoji are now set inside the block using the same attribute DSL as other step types. `Buildkite::Builder::Group` was removed and replaced by `Buildkite::Pipelines::Steps::Group`.
**Why:** Groups were previously a one-off class (`Builder::Group`) that accepted a label string directly rather than using the standard attribute system. Making group a proper step type under `Pipelines::Steps::Group` means it has full attribute support (including `label`, `key`, `depends_on`, and anything else Buildkite adds), and fits the same model as every other step type in the gem.

Before:

```ruby
Buildkite::Builder.pipeline do
  group("My Group", emoji: :partyparrot) do
    command(:rspec)
  end
end
```

After:

```ruby
Buildkite::Builder.pipeline do
  group do
    label "My Group", emoji: :partyparrot
    command(:rspec)
  end
end
```

**Migration:**
1. For every `group("label") { ... }` call, move the label inside the block as `label "label"`.
2. If you passed `emoji:` as an argument, move it inside the block: `label "My Label", emoji: :name`.
3. If you referenced `Buildkite::Builder::Group` in custom extensions or processors, update to `Buildkite::Pipelines::Steps::Group`.

**Verification:** Run `buildkite-builder preview <pipeline>` and confirm groups appear in the YAML output with the expected `group` key and label.
**Risk:** Medium. Every `group` call in every pipeline file needs updating, but the change is mechanical.

---

#### SubPipelines Removed

**What changed:** `Extensions::SubPipelines`, `PipelineCollection`, and the `pipeline(name) { ... }` DSL method are all removed. The `context.data.pipelines` collection no longer exists.
**Why:** Sub-pipelines were added in 3.1.0 as a way to define triggered pipelines inline and have their YAML written to artifacts at build time. They were never a Buildkite-native concept, and maintaining a parallel pipeline-within-a-pipeline DSL added significant complexity. Buildkite's trigger steps combined with separately uploaded pipeline YAMLs cover the same use case more cleanly.

Before:

```ruby
Buildkite::Builder.pipeline do
  pipeline("my-sub-pipeline") do
    label "My Sub-Pipeline"
    depends_on :setup

    command(:run_tests)
  end
end
```

After:

```ruby
# Define the sub-pipeline as its own pipeline file, then use a trigger step:
Buildkite::Builder.pipeline do
  trigger do
    label "My Sub-Pipeline"
    trigger "my-sub-pipeline"
    depends_on :setup
    build(
      message: '${BUILDKITE_MESSAGE}',
      commit: '${BUILDKITE_COMMIT}',
      branch: '${BUILDKITE_BRANCH}'
    )
  end
end
```

**Migration:**
1. For each `pipeline(name) { ... }` block, create a separate pipeline definition and upload it as its own Buildkite pipeline.
2. Replace the `pipeline(name) { ... }` call with a `trigger` step pointing at the new pipeline.
3. Remove any code that accessed `context.data.pipelines`.
4. Remove `BKB_SUBPIPELINE_FILE` from your Buildkite environment variables if it was only there for this feature.

**Verification:** Run `buildkite-builder preview <pipeline>` and confirm no `NoMethodError` for `pipeline` or `NameError` for `SubPipelines`. Verify trigger steps appear in the YAML output.
**Risk:** High if you used sub-pipelines. None if you didn't.

---

#### Template Handling Refactor

**What changed:** Template loading and application moved from `StepCollection` to `Extensions::Steps`. `StepCollection` no longer holds a `TemplateManager` reference (the `templates` reader was removed). Templates are now found by the `Steps` extension and applied via `step.process(template)` explicitly in `build_step`. `StepCollection#add` was also removed; steps are now built through `Extensions::Steps#build_step` and pushed directly.
**Why:** Having `StepCollection` own the template manager was a design smell: a collection type shouldn't be responsible for loading and applying templates. Moving this responsibility to the `Steps` extension keeps template lifecycle in one place and makes the step construction flow explicit.

**Migration:** For most consumers using the standard DSL (`command`, `block`, `trigger`, etc.), this change is invisible. If you wrote a custom extension that called `context.data.steps.add(StepClass, template_name)` directly, update it to use the DSL methods or call `context.extensions.find(Extensions::Steps).build_step(StepClass, template_name)` instead.
**Verification:** Run `buildkite-builder preview <pipeline>` and confirm template-based steps render correctly. If you have custom extensions, confirm they build without `NoMethodError` on `StepCollection`.
**Risk:** Low for pipeline authors. Medium for extension authors that bypassed the DSL and called `StepCollection#add` directly.

### 4.x Notable Minors

These are the consumer-facing additions and fixes across 4.x minor releases. If you're on an older 4.x version, here's what you're missing.

#### Step and Attribute Additions

**4.1.0: `skip` step type removed**

The `skip` step type was a thin wrapper that just set the `skip` attribute on a command step. It was removed to eliminate the confusion of having two ways to express the same thing. Use a plain `command` step with `skip` set directly:

```ruby
command do
  label "Lint"
  command "bundle exec rubocop"
  skip "Disabled while migrating"
end
```

**4.2.5: `skip` attribute on Block and Input steps**

Block and Input steps gained the `skip` attribute, matching what command steps already supported.

```ruby
block do
  label "Manual approval"
  skip ENV['CI_BYPASS_APPROVAL']
end
```

**4.13.0: `key` attribute on Wait steps**

Wait steps now support `key`, making them referenceable by other steps via `depends_on`.

```ruby
wait do
  key "test-gate"
end

command do
  label "Deploy"
  depends_on "test-gate"
end
```

**4.17.0: `notify` on Command steps**

Command steps gained a `notify` attribute for step-level notifications, separate from the pipeline-level `notify` extension.

```ruby
command do
  label "Deploy to production"
  command "scripts/deploy.sh"
  notify slack: "#deploys", message: "Deploy finished"
end
```

**4.19.0: Build matrix support**

Command steps support the `matrix` attribute for fan-out builds across combinations of values.

```ruby
command do
  label "Test %matrix.ruby%"
  command "bundle exec rspec"
  matrix setup: {
    ruby: ["3.1", "3.2", "3.3"]
  }
end
```

**4.20.0: `blocked_state` on Input steps**

Input steps support `blocked_state` to control what state the build is reported in while waiting.

```ruby
input do
  label "Review release"
  blocked_state "passed"  # or "running", "failed"
end
```

**4.21.0: `allowed_teams` on Block and Input steps**

Block and Input steps support `allowed_teams` to restrict who can unblock them.

```ruby
block do
  label "Approve production deploy"
  allowed_teams "platform-team"
  allowed_teams "security-team"
end
```

**4.23.0: Additional missing attributes**

Various step types received attributes that Buildkite supports but the gem was missing. If you've been working around missing attributes by manipulating raw hashes, check the current step definitions - the gap is much smaller now.

---

#### StepCollection Improvements

**4.11.0: Skip group traversal in `StepCollection#each`**

`StepCollection#each` by default traverses into groups and yields steps inside them. The new `traverse_groups:` option lets you opt out when you only want top-level steps.

```ruby
def build
  # Only top-level steps, no group traversal
  context.data.steps.each(:command, traverse_groups: false) do |step|
    step.label("#{step.label} [top-level only]")
  end
end
```

**4.12.0: `StepCollection#move` for reordering steps**

Extensions can now reorder steps without removing and re-adding them manually.

```ruby
def build
  setup = context.data.steps.find!(:setup)
  deploy = context.data.steps.find!(:deploy)

  # Move setup before deploy
  context.data.steps.move(setup, before: deploy)

  # Or move it after another step
  context.data.steps.move(deploy, after: setup)
end
```

**4.12.0: `depends_on` copy-by-reference fix**

Previously, copying a step's `depends_on` value (e.g., in an extension) could accidentally mutate shared state due to copy-by-reference. This is fixed. No migration needed, but if you had workarounds for this, they can be removed.

---

#### Templates and Extensions

**4.2.0: Shared global templates**

Templates placed in `.buildkite/templates/` (at the repo root, not inside a pipeline directory) are available to all pipelines. Previously, templates had to live inside the specific pipeline's `templates/` directory.

```
.buildkite/
  templates/
    common_command.rb    # Available to all pipelines
  pipelines/
    my-pipeline/
      templates/
        specific.rb      # Only available to my-pipeline
      pipeline.rb
```

```ruby
# pipeline.rb - uses the global template
Buildkite::Builder.pipeline do
  command(:common_command)
end
```

**4.18.0: Template definitions inside extensions**

Extensions can now define templates inline using `template(:name) { }` at the class level. This lets extensions ship their own templates without requiring consumers to create template files.

```ruby
class MyExtension < Buildkite::Builder::Extension
  template(:shared_step) do
    label "Shared Step"
    command "scripts/shared.sh"
    agents queue: "default"
  end

  def build
    pipeline do
      command(:shared_step)
    end
  end
end
```

---

#### Pipeline-Wide Settings

**4.10.0: Pipeline-wide `agents` extension**

A new built-in extension sets default agent selectors for the entire pipeline. Load it with `use(Buildkite::Builder::Extensions::Agents)` and call `agents(...)` in the pipeline block.

```ruby
Buildkite::Builder.pipeline do
  use(Buildkite::Builder::Extensions::Agents)

  agents queue: "my-queue", size: "large"

  command do
    label "Tests"
    command "bundle exec rspec"
    # Inherits queue: "my-queue", size: "large"
  end
end
```

**4.10.0: `priority` on Command steps**

Command steps support the `priority` attribute for controlling queue ordering.

```ruby
command do
  label "Critical path"
  command "scripts/critical.sh"
  priority 100
end
```

---

#### `Command::Result` Object (4.6.0)

`Buildkite::Pipelines::Command.run` (and the bang variant) now returns a `Command::Result` object instead of raw captured output. It wraps the `Open3.capture3` result and gives you structured access to stdout, stderr, and exit status.

```ruby
result = Buildkite::Pipelines::Command.run("buildkite-agent", "meta-data", "get", "my-key")
result.stdout   # => "the value\n"
result.stderr   # => ""
result.success? # => true
```

This replaces the old `capture: true` argument pattern from 3.x.

---

#### `depends_on` Fix (4.4.0)

Multiple `depends_on` calls on a step weren't being combined correctly. This is fixed. If you had workarounds (like passing all keys in a single call), they still work but you can simplify:

```ruby
command do
  label "Deploy"
  depends_on "build"
  depends_on "test"   # Now correctly appended alongside "build"
end
```

---

#### DependsOn Helper Removed (4.3.0)

The `DependsOn` helper module was removed. It didn't add anything beyond what the `depends_on` attribute already provided. If you were including or referencing `Buildkite::Pipelines::Helpers::DependsOn` directly in custom code, remove it.

---

#### Compatibility

**4.22.0: `benchmark` gem dependency added**

The `benchmark` gem was added as an explicit dependency for Ruby 4 compatibility (Ruby 4 removed it from the standard library). No action needed unless you're on a Ruby version where this causes a conflict.
