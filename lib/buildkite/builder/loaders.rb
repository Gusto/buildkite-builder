# frozen_string_literal: true

module Buildkite
  module Builder
    module Loaders
      autoload :Abstract, File.expand_path('loaders/abstract', __dir__)
      autoload :Manifests, File.expand_path('loaders/manifests', __dir__)
      autoload :Templates, File.expand_path('loaders/templates', __dir__)
      autoload :Extensions, File.expand_path('loaders/extensions', __dir__)
    end
  end
end
