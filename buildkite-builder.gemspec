$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'buildkite-builder'

Gem::Specification.new do |spec|
  spec.name          = "buildkite-builder"
  spec.version       = Buildkite::Builder::VERSION
  spec.authors       = ["Ngan Pham", "Andrew Lee"]
  spec.email         = ["gusto-opensource-buildkite@gusto.com"]

  spec.summary       = <<~SUMMARY.strip
    A gem for programmatically creating Buildkite pipelines.
  SUMMARY
  spec.description   = <<~DESCRIPTION.strip
    Buildkite Builder is a tool that provides projects using Buildkite to have dynamic pipeline functionality.
  DESCRIPTION
  spec.homepage      = 'https://github.com/Gusto/buildkite-builder'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Gusto/buildkite-builder"
  spec.metadata["changelog_uri"] = "https://github.com/Gusto/buildkite-builder/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/Gusto/buildkite-builder/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir["CHANGELOG.md", "LICENSE.txt", "README.md", "lib/**/*", "bin/**/*"]
  spec.executables   = ['buildkite-builder']
  spec.require_paths = ["lib"]
end
