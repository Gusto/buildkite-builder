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

<!-- TODO: Exhaustive list of breaking changes and notable additions in 3.0.0. Drawn from git log v2.4.1..v3.0.0. -->

### 4.0.0

<!-- TODO: Exhaustive list of breaking changes and notable additions in 4.0.0. Drawn from git log v3.9.0..v4.0.0. -->

### 4.x Notable Minors

<!-- TODO: Significant changes in 4.x minor releases. Cover any deprecations, new features, or behavioral changes worth calling out for teams staying on 4.x. -->
