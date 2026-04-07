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

<!-- TODO: Exhaustive list of breaking changes and notable additions in 2.0.0. Drawn from git log v1.5.0..v2.0.0. -->

### 3.0.0

<!-- TODO: Exhaustive list of breaking changes and notable additions in 3.0.0. Drawn from git log v2.4.1..v3.0.0. -->

### 4.0.0

<!-- TODO: Exhaustive list of breaking changes and notable additions in 4.0.0. Drawn from git log v3.9.0..v4.0.0. -->

### 4.x Notable Minors

<!-- TODO: Significant changes in 4.x minor releases. Cover any deprecations, new features, or behavioral changes worth calling out for teams staying on 4.x. -->
