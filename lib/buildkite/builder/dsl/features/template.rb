# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      module Features
        module Template
          def template(name, &definition)
            name = name.to_s

            if _context.templates.key?(name)
              raise ArgumentError, "Template already defined: #{name}"
            elsif !block_given?
              raise ArgumentError, 'Template definition block must be given'
            end

            _context.templates[name.to_s] = definition
          end
        end
      end
    end
  end
end
