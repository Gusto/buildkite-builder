# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers do
  describe '.prepend_attribute_helper' do
    context 'when attribute has a helper' do
      let(:attribute_helper_module) { Module.new }

      before do
        stub_const('Buildkite::Pipelines::Helpers::ATTRIBUTE_HELPERS', { valid: :Valid })
        stub_const('Buildkite::Pipelines::Helpers::Valid', attribute_helper_module)
      end

      it 'prepends the helper' do
        step_class = double

        expect(step_class).to receive(:prepend).with(attribute_helper_module)

        described_class.prepend_attribute_helper(step_class, :valid)
      end
    end

    context 'when attribute does not have a helper' do
      it 'does nothing' do
        step_class = double

        expect(step_class).not_to receive(:prepend)

        described_class.prepend_attribute_helper(step_class, :invalid)
      end
    end
  end

  describe '.sanitize' do
    context 'for hash objects' do
      it 'sanitizes keys' do
        expect(described_class.sanitize(foo: 'bar')).to eq('foo' => 'bar')
      end

      it 'sanitizes values' do
        expect(described_class.sanitize('foo' => :bar)).to eq('foo' => 'bar')
      end

      it 'recursively sanitizes' do
        expect(described_class.sanitize(foo: { foo2: :bar })).to eq('foo' => { 'foo2' => 'bar' })
      end
    end

    context 'for array objects' do
      it 'sanitizes all values' do
        expect(described_class.sanitize([:foo, :bar])).to eq(['foo', 'bar'])
      end

      it 'recursively sanitizes all values' do
        expect(described_class.sanitize([[:foo, :bar], { foo2: :bar2 }])).to eq([['foo', 'bar'], { 'foo2' => 'bar2' }])
      end
    end

    context 'for Symbols' do
      it 'sanitizes to string' do
        expect(described_class.sanitize(:foo)).to eq('foo')
      end
    end

    context 'for Pathname' do
      it 'sanitizes to string' do
        expect(described_class.sanitize(Pathname.new('foo'))).to eq('foo')
      end
    end
  end
end
