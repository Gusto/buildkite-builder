# frozen_string_literal: true

module Buildkite
  module Builder
    module Loaders
      class Templates < Abstract
        include Definition::Helper

        TEMPLATES_PATH = Pathname.new('templates').freeze

        def load
          load_from_path(global_path)
          load_from_path(pipeline_path)
        end

        private

        def load_from_path(path)
          return unless path.directory?

          path.children.sort.each do |file|
            add(file.basename('.rb'), load_definition(file, Definition::Template))
          end
        end

        def pipeline_path
          root.join(TEMPLATES_PATH)
        end

        def global_path
          buildkite_path.join(TEMPLATES_PATH)
        end
      end
    end
  end
end
