Gem::Specification.new do |spec|
  spec.name          = "buildkite-builder"
  spec.version       = File.read("VERSION").strip
  spec.authors       = ["Ngan Pham", "Andrew Lee"]
  spec.email         = ["gusto-opensource-buildkite@gusto.com"]

  spec.summary       = <<~SUMMARY.strip
    A gem for programmatically creating Buildkite pipelines.
  SUMMARY
  spec.description   = <<~DESCRIPTION.strip
    Buildkite Builder is a tool that provides projects using Buildkite to have dynamic pipeline functionality.
  DESCRIPTION
  spec.homepage      = "https://github.com/Gusto/buildkite-builder"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Gusto/buildkite-builder"
  spec.metadata["changelog_uri"] = "https://github.com/Gusto/buildkite-builder/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/Gusto/buildkite-builder/issues"

  spec.files         = Dir["VERSION", "CHANGELOG.md", "LICENSE.txt", "README.md", "lib/**/*", "bin/**/*"]
  spec.bindir        = "exe"
  spec.executables   = Dir["exe/*"].map { |exe| File.basename(exe) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rainbow", ">= 3"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"
end
