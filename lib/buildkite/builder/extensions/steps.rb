module Buildkite
  module Builder
    module Extensions
      class Steps < Extension
        attr_reader :templates

        def prepare
          @templates = TemplateManager.new(context.root)
          context.data.steps = StepCollection.new
        end

        def build_step(step_class, template_name, **args, &block)
          template = @templates.find(template_name)

          step_class.new(**args).tap do |step|
            step.process(template) if template
            step.process(block) if block_given?
            context.data.steps.push(step)
          end
        end

        dsl do
          def group(detached: false, &block)
            raise "Group does not allow nested in another Group" if context.is_a?(Group)

            if emoji
              emoji = Array(emoji).map { |name| ":#{name}:" }.join
              label = [emoji, label].compact.join(' ')
            end

            context.data.steps.push(Buildkite::Builder::Group.new(label, context, &block))
          end

          def block(template = nil, **args, &block)
            context.extensions.find(Steps).build_step(Pipelines::Steps::Block, template, **args, &block)
          end

          def command(template = nil, **args, &block)
            context.extensions.find(Steps).build_step(Pipelines::Steps::Command, template, **args, &block)
          end

          def input(template = nil, **args, &block)
            context.extensions.find(Steps).build_step(Pipelines::Steps::Input, template, **args, &block)
          end

          def trigger(template = nil, **args, &block)
            context.extensions.find(Steps).build_step(Pipelines::Steps::Trigger, template, **args, &block)
          end

          def skip(template = nil, **args, &block)
            context.extensions.find(Steps).build_step(Pipelines::Steps::Skip, template, **args, &block).tap do |step|
              # A skip step has a nil/noop command.
              step.command(nil)
              # Always set the skip attribute if it's in a falsey state.
              step.skip(true) if !step.get(:skip) || step.skip.empty?
            end
          end

          def wait(attributes = {}, &block)
            context.extensions.find(Steps).build_step(Pipelines::Steps::Wait, nil, &block).tap do |step|
              step.wait(nil)
              attributes.each do |key, value|
                step.set(key, value)
              end
            end
          end
        end
      end
    end
  end
end
