# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      autoload :Abstract, File.expand_path('dsl/abstract', __dir__)
      autoload :Features, File.expand_path('dsl/features', __dir__)
      autoload :Pipeline, File.expand_path('dsl/pipeline', __dir__)
    end
  end
end
