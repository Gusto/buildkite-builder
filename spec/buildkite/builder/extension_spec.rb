# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Extension do
  describe '.template' do
    context 'when registering a template' do
      it 'creates and stores an ExtensionTemplate' do
        template = described_class.template(:foo) { }

        expect(template).to be_a(Buildkite::Builder::ExtensionTemplate)
        expect(described_class.templates['foo']).to eq(template)
      end
    end

    context 'when template name already exists' do
      it 'raises an error' do
        described_class.template(:bar) { }

        expect {
          described_class.template(:bar) { }
        }.to raise_error(ArgumentError, "Template bar already registered in Buildkite::Builder::Extension")
      end
    end
  end
end
