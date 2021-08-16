module Buildkite
  module Builder
    module Extensions
      class Steps < Extension
        def prepare
          context.data[:steps] = StepCollection.new(
            TemplateRegistry.new(context.root),
            PluginRegistry.new
          )
        end

        dsl do
          def group(label = nil, &block)
            raise "Group does not allow nested in another Group" if context.is_a?(Group)

            context.data[:steps].push(Buildkite::Builder::Group.new(label, context, &block))
          end

          def plugin(name, uri, version)
            context.data[:steps].plugins.add(name, uri, version)
          end

          def block(template = nil, **args, &block)
            context.data[:steps].add(Pipelines::Steps::Block, template, **args, &block)
          end

          def command(template = nil, **args, &block)
            context.data[:steps].add(Pipelines::Steps::Command, template, **args, &block)
          end

          def input(template = nil, **args, &block)
            context.data[:steps].add(Pipelines::Steps::Input, template, **args, &block)
          end

          def trigger(template = nil, **args, &block)
            context.data[:steps].add(Pipelines::Steps::Trigger, template, **args, &block)
          end

          def skip(template = nil, **args, &block)
            step = context.data[:steps].add(Pipelines::Steps::Skip, template, **args, &block)
            # A skip step has a nil/noop command.
            step.command(nil)
            # Always set the skip attribute if it's in a falsey state.
            step.skip(true) if !step.get(:skip) || step.skip.empty?
            step
          end

          def wait(attributes = {}, &block)
            step = context.data[:steps].add(Pipelines::Steps::Wait, &block)
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
