require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :docker do
  task :release do
    version = File.read("VERSION").strip
    puts "🔨 Building docker image for release of Buildkite Builder version #{version}"

    system("docker build --tag=gusto/buildkite-builder:#{version} --platform linux/x86_64 --build-arg version=#{version} .", exception: true)

    puts "📦 Pushing to DockerHub: gusto/buildkite-builder:#{version}"
    system("docker push gusto/buildkite-builder:#{version}", exception: true)
    puts "✅ Done!"
  end
end
