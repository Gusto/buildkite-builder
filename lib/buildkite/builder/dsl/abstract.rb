module Buildkite
  module Builder
    module DSL
      class Abstract
        def data
          @data ||= {}
        end

        def initialize
          @templates = {}
        end

        def template(name, &definition)
          name = name.to_s

          if @templates.key?(name)
            raise ArgumentError, "Template already defined: #{name}"
          elsif !block_given?
            raise ArgumentError, 'Template definition block must be given'
          end

          @templates[name.to_s] = definition
        end

        private

        def find_template(name)
          return unless name

          @templates[name.to_s] || begin
            raise ArgumentError, "Template not defined: #{name}"
          end
        end

        def add_to_steps(step_class, template = nil, **args, &block)
          data[:steps] ||= []
          data[:steps].push(step_class.new(self, find_template(template), **args, &block)).last
        end
      end
    end
  end
end
