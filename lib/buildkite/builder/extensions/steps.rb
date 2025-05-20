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
          template = find_template(template_name)

          step_class.new(**args).tap do |step|
            step.process(template) if template
            step.process(block) if block_given?

            if @current_group
              @current_group.steps.push(step)
            else
              context.data.steps.push(step)
            end
          end
        end

        def with_group(group, &block)
          raise "Group cannot be nested" if @current_group

          @current_group = group

          group.process(block)
          context.data.steps.push(group).last
        ensure
          @current_group = nil
        end

        private

        def find_template(template_name)
          case template_name
          when Buildkite::Builder::Extension::Template
            template_name.block
          when Buildkite::Builder::Extension
            unless context.extensions.all.include?(template_name)
              raise ArgumentError, "#{template_name} extension is not registered"
            end
            
            find_template(context.extensions.find(template_name).template)
          else
            @templates.find(template_name)
          end
        end

        dsl do
          def group(&block)
            context.extensions.find(Steps).with_group(Pipelines::Steps::Group.new(context), &block)
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

          def wait(attributes = {}, &block)
            context.extensions.find(Steps).build_step(Pipelines::Steps::Wait, nil, &block).tap do |step|
              step.wait(nil)
              attributes.each do |key, value|
                step.public_send(key, value)
              end
            end
          end
        end
      end
    end
  end
end
