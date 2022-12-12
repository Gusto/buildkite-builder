# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extensions::Plugins do
  before do
    setup_project(fixture_project)
  end

  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:pipeline) { Buildkite::Builder::Pipeline.new(fixture_path) }
  let(:extension) { pipeline.extensions.find(described_class) }

  describe 'dsl methods' do
    describe '#plugin' do
      it 'adds the extension to the manager' do
        pipeline.dsl.plugin(:foo, 'foo#v1.2.3')

        expect(extension.manager.build(:foo)).to eq( {'foo#v1.2.3' => {} })
      end
    end
  end

  describe '#manager' do
    it 'returns the plugin manager' do
      expect(pipeline.extensions.find(described_class).manager).to be_a(Buildkite::Builder::PluginManager)
    end
  end

  describe '#build' do
    it 'coverts all plugins in the manager' do
      pipeline.dsl.plugin(:foo, 'foo#v1.2.3', default_key1: 'value1')
      pipeline.dsl.command do
        plugin :foo, key2: 'value2'
        plugin 'bar#v1.2'
      end

      plugins = pipeline.to_h.dig("steps", 0, "plugins")
      expect(plugins[0]).to eq({
        "foo#v1.2.3" => {
          "default_key1" => "value1",
          "key2" => "value2"
        }
      })
      expect(plugins[1]).to eq({
        "bar#v1.2" => {}
      })
    end
  end
end
