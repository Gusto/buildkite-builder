# frozen_string_literal: true

RSpec.describe Buildkite::Builder::TemplateRegistry do
  let(:fixture_project) { :basic }
  let(:fixture_path) { fixture_pipeline_path_for(fixture_project, :dummy) }
  let(:registry) { described_class.new(fixture_path) }

  before do
    setup_project(fixture_project)
  end

  describe '#new' do
    it 'loads template' do
      expect(Buildkite::Builder::Loaders::Templates).to receive(:load).with(fixture_path).and_return({})

      registry
    end
  end

  describe '#find' do
    context 'when template exists' do
      it 'returns the template definition' do
        template = registry.find(:basic)

        expect(template).to be_a(Buildkite::Builder::Definition::Template)
      end
    end

    context 'when template does not exist' do
      it 'raises error' do
        expect {
          registry.find(:foo)
        }.to raise_error(ArgumentError, "Template not defined: foo")
      end
    end

    context 'when name is nil' do
      it 'returns nil' do
        expect(registry.find(nil)).to be_nil
      end
    end
  end
end
