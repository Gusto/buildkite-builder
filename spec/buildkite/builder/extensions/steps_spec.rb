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

      describe '#skip' do
        include_examples 'a step type', Buildkite::Pipelines::Steps::Skip

        it 'sets the command attribute' do
          step = pipeline.dsl.skip(template) do
            skip 'foo-skip'
            command 'invalid'
          end

          expect(step.skip).to eq('foo-skip')
          expect(step.has?(:command)).to eq(true)
          expect(step.command).to be_nil
        end

        it 'sets the skip attribute' do
          step = pipeline.dsl.skip(template) do
            label 'Foo'
          end
          expect(step.skip).to eq(true)

          step = pipeline.dsl.skip(template) do
            label 'Foo'
            skip ''
          end
          expect(step.skip).to eq(true)

          step = pipeline.dsl.skip(template) do
            label 'Foo'
            skip false
          end
          expect(step.skip).to eq(true)
        end
      end
    end
  end
end
