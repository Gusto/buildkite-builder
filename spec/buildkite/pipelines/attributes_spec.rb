# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Attributes do
  let(:step_class) do
    stub_const('FooStep', Class.new { include Buildkite::Pipelines::Attributes })
  end
  let(:step) { step_class.new }

  describe '.permitted_attributes' do
    it 'returns addes attribues' do
      step_class.attribute :foo
      step_class.attribute :bar
      step_class.attribute :baz, as: :fooo
      step_class.attribute :boo, append: true

      expect(step_class.permitted_attributes).to eq(Set.new(['foo', 'bar', 'baz', 'boo']))
    end
  end

  describe '.permits?' do
    before { step_class.attribute(:foo) }

    it 'returns true when permitted' do
      expect(step_class.permits?(:foo)).to eq(true)
    end

    it 'returns false when not permitted' do
      expect(step_class.permits?(:bar)).to eq(false)
    end
  end

  describe '.attribute' do
    it 'defines a read-write method' do
      step_class.attribute :bar

      step = step_class.new

      step.bar(123)
      expect(step.bar).to eq(123)
    end

    it 'defines a query method' do
      step_class.attribute :bar

      step = step_class.new

      expect(step.bar?(123)).to eq(true)
      expect(step.bar?(456)).to eq(false)
      expect(step.bar).to eq(123)

      step.unset(:bar)
      expect(step.bar?(456)).to eq(true)
      expect(step.bar).to eq(456)
    end

    context 'when already defined' do
      it 'raises error' do
        step_class.attribute :foo

        expect {
          step_class.attribute :foo
        }.to raise_error('Step already defined attribute: foo')
      end
    end

    context 'when :as is specified' do
      it 'defines a read-write method' do
        step_class.attribute :bar, as: :baz

        step = step_class.new

        step.baz(123)
        expect(step.baz).to eq(123)
        expect(step.respond_to?(:bar)).to eq(false)
        expect(step.respond_to?(:bar?)).to eq(false)
      end
    end

    context 'when :append is specified' do
      it 'defines step method which maps values to array' do
        step_class.attribute :baz, append: true

        step = step_class.new

        step.baz(123)
        step.baz(234)
        expect(step.baz).to eq([123, 234])

        step.baz!(345)
        expect(step.baz).to eq([345])
      end
    end
  end

  describe '#set' do
    before { step_class.attribute(:foo) }

    context 'with valid attribute' do
      it 'sets attribute with value' do
        step.set(:foo, 123)

        expect(step.foo).to eq(123)
      end
    end

    context 'with invalid attribute' do
      it 'raises' do
        expect {
          step.set(:bar, 123)
        }.to raise_error('Attribute not permitted on FooStep step: bar')
      end
    end
  end

  describe '#unset' do
    before do
      step_class.attribute(:foo)
      step.foo(123)
    end

    it 'removes from defined attributes' do
      step.unset(:foo)

      expect(step.foo).to eq(nil)
    end
  end

  describe '#get' do
    before { step_class.attribute(:foo) }

    it 'returns value for set attributes' do
      step.foo('foo')

      expect(step.get(:foo)).to eq('foo')
    end
  end

  describe '#has?' do
    before do
      step_class.attribute(:foo)
      step_class.attribute(:bar)
    end

    it 'returns boolean whether or not certain attribute was set' do
      step.foo('foo')

      expect(step.has?(:foo)).to eq(true)
      expect(step.has?(:bar)).to eq(false)
    end

    it 'does not validate' do
      expect {
        step.has?(:invalid)
      }.not_to raise_error
    end
  end

  describe '#append' do
    before { step_class.attribute(:foo) }

    it 'can append multiple values' do
      step.set(:foo, 'foo1')
      step.append(:foo, ['foo2', 'foo3'])

      expect(step.foo).to eq(['foo1', 'foo2', 'foo3'])
    end

    context 'when attribute was not an array' do
      it 'turns to an array' do
        step.append(:foo, 'foo')

        expect(step.foo).to eq(['foo'])
      end
    end

    context 'when attribute already has array-ed values' do
      it 'appends to array' do
        step.append(:foo, 'foo')
        step.append(:foo, 'bar')

        expect(step.foo).to eq(['foo', 'bar'])
      end
    end
  end

  describe '#prepend' do
    before { step_class.attribute(:foo) }

    it 'can append multiple values' do
      step.set(:foo, 'foo1')
      step.prepend(:foo, ['foo2', 'foo3'])

      expect(step.foo).to eq(['foo2', 'foo3', 'foo1'])
    end

    context 'when attribute was not an array' do
      it 'turns to an array' do
        step.append(:foo, 'foo')

        expect(step.foo).to eq(['foo'])
      end
    end

    context 'when attribute already has array-ed values' do
      it 'appends to array' do
        step.prepend(:foo, 'foo')
        step.prepend(:foo, 'bar')

        expect(step.foo).to eq(['bar', 'foo'])
      end
    end
  end

  describe '#permits?' do
    before { step_class.attribute(:foo) }

    it 'returns true when permitted' do
      expect(step.permits?(:foo)).to eq(true)
    end

    it 'returns false when not permitted' do
      expect(step.permits?(:bar)).to eq(false)
    end
  end

  describe '#to_h' do
    before do
      step_class.attribute :foo1
      step_class.attribute :foo2
      step_class.attribute :foo3
    end

    it 'returns sorted attributes' do
      step.foo3('value3')
      step.foo1('value1')
      step.foo2('value2')

      expect(step.to_h.keys).to eq(['foo1', 'foo2', 'foo3'])
    end
  end
end
