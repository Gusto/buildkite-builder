# frozen_string_literal: true

module Buildkite
  module Builder
    module Dsl
      module Features
        autoload :Env, File.expand_path('features/env', __dir__)
        autoload :Block, File.expand_path('features/block', __dir__)
        autoload :Command, File.expand_path('features/command', __dir__)
        autoload :Group, File.expand_path('features/group', __dir__)
        autoload :Input, File.expand_path('features/input', __dir__)
        autoload :Notify, File.expand_path('features/notify', __dir__)
        autoload :Skip, File.expand_path('features/skip', __dir__)
        autoload :Template, File.expand_path('features/template', __dir__)
        autoload :Trigger, File.expand_path('features/trigger', __dir__)
        autoload :Wait, File.expand_path('features/wait', __dir__)

        module Helpers
          def self.add_to_steps(owner, step_class, template = nil, **args, &block)
            if template
              template_definition = owner.templates[template.to_s] || begin
                raise ArgumentError, "Template not defined: #{template}"
              end
            end

            owner.steps.push(step_class.new(template_definition, **args, &block)).last
          end
        end
      end
    end
  end
end
