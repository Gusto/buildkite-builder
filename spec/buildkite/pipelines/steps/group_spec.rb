# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Steps::Group do
  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }

  before do
    setup_project(fixture_project)
  end

  describe '#to_h' do
    it 'merges attributes with steps' do
      group = described_class.new(pipeline)
      group.label('Group')

      step = pipeline.dsl.command do
        label 'Command'
        command 'false'
      end

      group.steps.push(step)

      expect(group.to_h).to eq(
        group: nil,
        'label' => 'Group',
        steps: [
          {
            'label' => 'Command',
            'command' => ['false']
          }
        ]
      )
    end
  end
end
