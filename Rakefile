require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :docker do
  task :release do
    version = "1.0.0.beta.5"
    system("docker build --tag=gusto/buildkite-builder:#{version} --build-arg version=#{version} .", exception: true)
    system("docker push gusto/buildkite-builder:#{version}", exception: true)
  end
end
