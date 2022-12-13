# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Group do
  before do
    setup_project(fixture_project)
  end

  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }

  describe '#to_h' do
    let(:group) { described_class.new('foo', pipeline) }

    it 'returns the data with group info' do
      expect(group.to_h).to eq(group: 'foo')
    end

    context 'with definitions' do
      it 'returns the data with group step definitions' do
        group = described_class.new('foo', pipeline) do
          notify email: 'foo@bar.com'
          notify basecamp_campfire: 'basecamp_uri'
          command do
            label 'foo'
            command 'true'
          end
          key 'foo_group'
          depends_on :one, :two

          wait
        end

        expect(Buildkite::Pipelines::Helpers.sanitize(group.to_h)).to eq(
          'group' => 'foo',
          'notify' => [
            {
              'email' => 'foo@bar.com'
            },
            {
              'basecamp_campfire' => 'basecamp_uri'
            }
          ],
          'key' => 'foo_group',
          'depends_on' => [
            'one',
            'two'
          ],
          'steps' => [
            {
              'command' => ['true'],
              'label' => 'foo'
            },
            {
              'wait' => nil
            }
          ]
        )
      end
    end
  end
end
