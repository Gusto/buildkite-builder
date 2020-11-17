# frozen_string_literal: true

module Buildkite
  autoload :Env, File.expand_path('buildkite/env', __dir__)
  autoload :Builder, File.expand_path('buildkite/builder', __dir__)
  autoload :Pipelines, File.expand_path('buildkite/pipelines', __dir__)

  def self.env
    unless defined?(@env)
      @env = Env.load(ENV)
    end
    @env
  end
end
