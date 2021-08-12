module Buildkite
  module Builder
    module Extensions
      class Steps < Extension
        class Helpers
          def self.add_to_steps(templates, steps, step_class, template = nil, **args, &block)
            if template
              template_definition = templates[template.to_s] || begin
                raise ArgumentError, "Template not defined: #{template}"
              end
            end

            steps.push(step_class.new(template_definition, **args, &block)).last
          end
        end

        dsl do
          def group(label = nil, &block)
            raise "Group does not allow nested in another Group" if context.is_a?(Group)

            data[:steps].push(Buildkite::Builder::Group.new(label, context.templates, &block))
          end

          def block(template = nil, **args, &block)
            Extensions::Steps::Helpers.add_to_steps(context.templates, data[:steps], Pipelines::Steps::Block, template, **args, &block)
          end

          def command(template = nil, **args, &block)
            Extensions::Steps::Helpers.add_to_steps(context.templates, data[:steps], Pipelines::Steps::Command, template, **args, &block)
          end

          def input(template = nil, **args, &block)
            Extensions::Steps::Helpers.add_to_steps(context.templates, data[:steps], Pipelines::Steps::Input, template, **args, &block)
          end

          def trigger(template = nil, **args, &block)
            Extensions::Steps::Helpers.add_to_steps(context.templates, data[:steps], Pipelines::Steps::Trigger, template, **args, &block)
          end

          def skip(template = nil, **args, &block)
            step = Extensions::Steps::Helpers.add_to_steps(context.templates, data[:steps], Pipelines::Steps::Skip, template, **args, &block)
            # A skip step has a nil/noop command.
            step.command(nil)
            # Always set the skip attribute if it's in a falsey state.
            step.skip(true) if !step.get(:skip) || step.skip.empty?
            step
          end

          def wait(attributes = {}, &block)
            step = Extensions::Steps::Helpers.add_to_steps(context.templates, data[:steps], Pipelines::Steps::Wait, &block)
            step.wait(nil)
            attributes.each do |key, value|
              step.set(key, value)
            end
            step
          end
        end
      end
    end
  end
end
