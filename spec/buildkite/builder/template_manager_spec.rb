# frozen_string_literal: true

RSpec.describe Buildkite::Builder::TemplateManager do
  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:manager) { described_class.new(fixture_path) }

  before do
    setup_project(fixture_project)
  end

  describe '#new' do
    it 'loads template' do
      expect(Buildkite::Builder::Loaders::Templates).to receive(:load).with(fixture_path).and_return({})

      manager
    end
  end

  describe '#find' do
    context 'when template exists' do
      it 'returns the template definition' do
        template = manager.find(:basic)

        expect(template).to be_a(Buildkite::Builder::Definition::Template)
      end
    end

    context 'when template does not exist' do
      it 'raises error' do
        expect {
          manager.find(:foo)
        }.to raise_error(ArgumentError, "Template not defined: foo")
      end
    end

    context 'when name is nil' do
      it 'returns nil' do
        expect(manager.find(nil)).to be_nil
      end
    end
  end
end
