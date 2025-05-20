# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Steps do
  before do
    setup_project(fixture_project)
  end

  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }
  let(:extension) { pipeline.extensions.find(described_class) }

  describe '#new' do
    let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new, root: Buildkite::Builder.root) }
    let(:dsl) do
      Buildkite::Builder::Dsl.new(context).extend(described_class)
    end

    before { context.dsl = dsl }

    it 'sets steps' do
      described_class.new(context)
      expect(context.data.steps).to be_a(Buildkite::Builder::StepCollection)
    end
  end

  context 'dsl methods' do
    describe 'group' do
      it 'adds group to steps' do
        pipeline.dsl.group do
          command do
            command 'true'
          end
        end

        expect(pipeline.data.steps.steps.last).to be_a(Buildkite::Pipelines::Steps::Group)
      end

      it 'supports emoji' do
        pipeline.dsl.group do
          label 'Label', emoji: :foo
          command do
            command 'true'
          end
        end

        group = pipeline.data.steps.steps.last
        expect(group.label).to eq(':foo: Label')
      end
    end

    context 'steps' do
      let(:template) { 'dummy' }
      shared_examples 'a step type' do |type|
        it 'adds and returns the step' do
          steps = pipeline.data.steps.steps.size
          step = pipeline.dsl.public_send(type.to_sym)
          expect(pipeline.data.steps.steps.last).to eq(step)
          expect(pipeline.data.steps.steps.size).to eq(steps + 1)

          step = pipeline.dsl.public_send(type.to_sym)
          expect(pipeline.data.steps.steps.last).to eq(step)
          expect(pipeline.data.steps.steps.size).to eq(steps + 2)
        end
      end

      shared_examples 'a step type that uses named steps' do |type|
        it 'loads the step from the given name' do
          step = pipeline.dsl.public_send(type.to_sym, template) { condition('foobar') }

          expect(step).to be_a(type)
          expect(step.condition).to eq('foobar')
        end

        it 'allows adhoc declaration' do
          step = pipeline.dsl.public_send(type.to_sym, template)
          step.condition('foobar')

          expect(step).to be_a(type)
          expect(step.condition).to eq('foobar')
        end
      end

      describe '#group' do
        it 'adds and returns the step' do
          steps = pipeline.data.steps.steps.size
          step = pipeline.dsl.group do
            label 'Group'
          end
          expect(pipeline.data.steps.steps.last).to eq(step)
          expect(pipeline.data.steps.steps.size).to eq(steps + 1)
        end
      end

      describe '#block' do
        include_examples 'a step type', Buildkite::Pipelines::Steps::Block
        include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Block
      end

      describe '#command' do
        include_examples 'a step type', Buildkite::Pipelines::Steps::Command
        include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Command
      end

      describe '#trigger' do
        include_examples 'a step type', Buildkite::Pipelines::Steps::Trigger
        include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Trigger
      end

      describe '#input' do
        include_examples 'a step type', Buildkite::Pipelines::Steps::Input
        include_examples 'a step type that uses named steps', Buildkite::Pipelines::Steps::Input
      end

      describe '#wait' do
        include_examples 'a step type', Buildkite::Pipelines::Steps::Wait

        it 'sets the wait attribute' do
          step = pipeline.dsl.wait

          expect(step.has?(:wait)).to eq(true)
          expect(step.wait).to be_nil
        end

        it 'allows adhoc declaration' do
          step = pipeline.dsl.wait { condition('foobar') }

          expect(step).to be_a(Buildkite::Pipelines::Steps::Wait)
          expect(step.condition).to eq('foobar')
          expect(step.has?(:wait)).to eq(true)
          expect(step.wait).to be_nil
        end

        it 'allows passed in options' do
          step = pipeline.dsl.wait(continue_on_failure: true)

          expect(step.continue_on_failure).to eq(true)
        end
      end
    end
  end

  context 'template methods' do
    let(:command_step) { Buildkite::Pipelines::Steps::Command.new }

    before do
      allow(Buildkite::Pipelines::Steps::Command)
        .to receive(:new).and_return(command_step)
    end

    describe 'when two extension templates have the same name' do
      it 'raises an error' do
        expect {
          Class.new(Buildkite::Builder::Extension) do
            template :default do; end
            template :foo do; end
            template :default do; end
          end
        }.to raise_error(ArgumentError, /Template default already registered/)
      end
    end

    describe 'when a template is not registered' do
      it 'raises an error' do
        stub_const('FooExtension', Class.new)

        expect {
          extension.build_step(Buildkite::Pipelines::Steps::Command, FooExtension)
        }.to raise_error(ArgumentError, /FooExtension extension is not registered/)
      end
    end

    describe '#build_step with different template sources' do
      it 'handles nil template (block-only)' do
        extension.build_step(Buildkite::Pipelines::Steps::Command, nil) do
          label 'Only from block'
          command 'echo "Command from block"'
        end

        expect(command_step.label).to eq('Only from block')
        expect(command_step.command).to match_array(['echo "Command from block"'])
      end

      it 'applies inline proc template' do
        template_proc = proc do
          label 'Template label'
          command 'echo "Template command"'
          env TEMPLATE: 'YES'
        end
        allow(extension.templates).to receive(:find)
          .with('string_template').and_return(template_proc)

        extension.build_step(Buildkite::Pipelines::Steps::Command, 'string_template') do |context|
          context.step.command << 'echo "Additional template command"'
          env FROM_BLOCK: 'true', FOO: 'bar'
        end

        expect(command_step.label).to eq('Template label')
        expect(command_step.command).to match_array(['echo "Template command"', 'echo "Additional template command"'])
        expect(command_step.env).to eq(FROM_BLOCK: 'true', FOO: 'bar')
      end

      it 'applies the default template from an extension class' do
        extender = Class.new(Buildkite::Builder::Extension) do
          template :default do
            label 'Default label'
            command 'echo "From default template"'
            env TEMPLATE_VAR: 'DEFAULT'
          end
        end
        stub_const('TmpDefaultTemplateExt', extender)
        pipeline.extensions.use(extender)

        extension.build_step(Buildkite::Pipelines::Steps::Command, extender) do
          label 'Override label'
        end

        expect(command_step.label).to eq('Override label')
        expect(command_step.command).to match_array(['echo "From default template"'])
        expect(command_step.env).to eq(TEMPLATE_VAR: 'DEFAULT')
      end

      it 'applies a named template via TemplateInfo' do
        extender = Class.new(Buildkite::Builder::Extension) do
          template :custom do
            label 'Custom label'
            command 'echo "Custom command"'
            env TEMPLATE_VAR: 'CUSTOM'
          end
        end
        stub_const('TmpCustomTemplateExt', extender)
        pipeline.extensions.use(extender)

        template_info = extender.template(:custom)

        extension.build_step(Buildkite::Pipelines::Steps::Command, template_info) do
          timeout_in_minutes 10
        end

        expect(command_step.label).to eq('Custom label')
        expect(command_step.command).to match_array(['echo "Custom command"'])
        expect(command_step.env).to eq(TEMPLATE_VAR: 'CUSTOM')
        expect(command_step.timeout_in_minutes).to eq(10)
      end
    end
  end
end
