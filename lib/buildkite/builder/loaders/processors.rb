# frozen_string_literal: true

require 'pathname'

module Buildkite
  module Builder
    module Loaders
      class Processors < Abstract
        PROCESSORS_PATH = Pathname.new('processors').freeze

        def load
          load_processors_from_path(global_processors_path)
          load_processors_from_path(pipeline_processors_path)
        end

        private

        def load_processors_from_path(path)
          return unless path.directory?

          path.children.map do |file|
            required_status = require(file.to_s)
            add(file.basename, { required: required_status })
          end
        end

        def global_processors_path
          buildkite_path.join(PROCESSORS_PATH)
        end

        def pipeline_processors_path
          root.join(PROCESSORS_PATH)
        end
      end
    end
  end
end
