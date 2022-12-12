# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Group do
  let(:root) { Buildkite::Builder.root }
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new, root: Buildkite::Builder.root) }
  let(:dsl) { Buildkite::Builder::Dsl.new(context) }

  before do
    context.data.steps = Buildkite::Builder::StepCollection.new(Buildkite::Builder::TemplateManager.new(root))
    context.dsl = dsl
  end

  describe '#to_h' do
    let(:group) { described_class.new('foo', context) }

    it 'returns the data with group info' do
      expect(group.to_h).to eq(group: 'foo')
    end

    context 'with definitions' do
      before do
        dsl.extend(Buildkite::Builder::Extensions::Notify)
        dsl.extend(Buildkite::Builder::Extensions::Steps)
      end

      it 'returns the data with group step definitions' do
        group = described_class.new('foo', context) do
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
