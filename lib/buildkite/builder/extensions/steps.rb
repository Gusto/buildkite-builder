module Buildkite
  module Builder
    module Extensions
      class Steps < Extension
        def prepare
          context.data[:steps] = StepsCollection.new(context)
          context.data[:templates] = TemplateRegistry.new(context)
          context.data[:plugins] = PluginRegistry.new(context)
        end

        class Helpers
          def self.add_to_steps(templates, data, step_class, template = nil, **args, &block)
            data[:steps] ||= StepsCollection.new

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

            context.data[:steps].push(Buildkite::Builder::Group.new(label, context, &block))
          end

          def plugin(name, uri, version)
            context.data[:plugins].add(name, uri, version)
          end

          def block(template = nil, **args, &block)
            context.data[:steps].add(Pipelines::Steps::Block, template, **args, &block)
          end

          def command(template = nil, **args, &block)
            context.data[:steps].add(Pipelines::Steps::Command, template, **args, &block)
          end

          def input(template = nil, **args, &block)
          end

          def trigger(template = nil, **args, &block)
          end

          def skip(template = nil, **args, &block)
            step = Extensions::Steps::Helpers.add_to_steps(context.templates, data, Pipelines::Steps::Skip, template, **args, &block)
            # A skip step has a nil/noop command.
            step.command(nil)
            # Always set the skip attribute if it's in a falsey state.
            step.skip(true) if !step.get(:skip) || step.skip.empty?
            step
          end

          def wait(attributes = {}, &block)
            step = Extensions::Steps::Helpers.add_to_steps(context.templates, data, Pipelines::Steps::Wait, &block)
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
