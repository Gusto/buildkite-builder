# frozen_string_literal: true

module Buildkite
  module Builder
    module Processors
      autoload :Abstract, File.expand_path('processors/abstract', __dir__)
    end
  end
end
