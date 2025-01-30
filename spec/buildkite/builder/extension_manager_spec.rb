# frozen_string_literal: true

RSpec.describe Buildkite::Builder::ExtensionManager do
  let(:root) { Buildkite::Builder.root }
  let(:context) { OpenStruct.new(data: Buildkite::Builder::Data.new, root: root, dsl: nil, logger: Logger.new(IO::NULL)) }
  let(:manager) { described_class.new(context) }

  before do
    context.dsl = Buildkite::Builder::Dsl.new(context)
  end

  describe '#new' do
    it 'loads all extensions' do
      expect(Buildkite::Builder::Loaders::Extensions).to receive(:load).with(context.root)

      described_class.new(context)
    end
  end

  describe '#use' do
    subject { manager.use(extension) }

    let(:extension) do
      Class.new(Buildkite::Builder::Extension) do
        def self.name
          'FooExtension'
        end

        dsl do
          def foo; end
        end
      end
    end

    it 'adds extension to collection and extend to context dsl' do
      subject

      expect(manager.find(extension)).to be_a(extension)
      expect(context.dsl.respond_to?(:foo)).to eq(true)
    end

    context 'when uses twice' do
      it 'raises error' do
        subject
        expect {
          manager.use(extension)
        }.to raise_error(RuntimeError, "FooExtension already registered")
      end
    end

    context 'when extension does not inherit from Buildkite::Builder::Extension' do
      let(:extension) do
        Class.new do
          def self.name
            'FooExtension'
          end
        end
      end

      it 'raises error' do
        expect {
          subject
        }.to raise_error(RuntimeError, "FooExtension must subclass Buildkite::Builder::Extension")
      end
    end
  end

  describe '#build' do
    let(:extension) do
      Class.new(Buildkite::Builder::Extension) do
        def self.name
          'FooExtension1'
        end
      end
    end

    let(:other_extension) do
      Class.new(Buildkite::Builder::Extension) do
        def self.name
          'FooExtension2'
        end
      end
    end

    it 'calls build on all registered extension' do
      manager.use(extension)
      manager.use(other_extension)

      extension_instance = manager.find(extension)
      other_extension_instance = manager.find(other_extension)

      expect(extension_instance).to receive(:build)
      expect(other_extension_instance).to receive(:build)

      manager.build
    end
  end
end
