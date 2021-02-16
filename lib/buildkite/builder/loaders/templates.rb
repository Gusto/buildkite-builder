# frozen_string_literal: true

module Buildkite
  module Builder
    module Loaders
      class Templates < Abstract
        include Definition::Helper

        TEMPLATES_PATH = Pathname.new('templates').freeze

        def load
          return unless templates_path.directory?

          templates_path.children.sort.each do |file|
            add(file.basename('.rb'), load_definition(file, Definition::Template))
          end
        end

        def templates_path
          root.join(TEMPLATES_PATH)
        end
      end
    end
  end
end
