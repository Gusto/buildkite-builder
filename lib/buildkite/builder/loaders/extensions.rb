# frozen_string_literal: true

require 'pathname'

module Buildkite
  module Builder
    module Loaders
      class Extensions < Abstract
        EXTENSIONS_PATH = Pathname.new('extensions').freeze

        def load
          load_extensions_from_path(global_extensions_path)
          load_extensions_from_path(pipeline_extensions_path)
        end

        private

        def load_extensions_from_path(path)
          return unless path.directory?

          path.children.map do |file|
            required_status = require(file.to_s)
            add(file.basename, { required: required_status })
          end
        end

        def global_extensions_path
          buildkite_path.join(EXTENSIONS_PATH)
        end

        def pipeline_extensions_path
          root.join(EXTENSIONS_PATH)
        end
      end
    end
  end
end
