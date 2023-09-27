# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::DependsOn do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :depends_on, append: true
    end
  end

  let(:step) { step_klass.new }

  describe '#depends_on' do
    it 'flatterns the value' do
      step.depends_on([:foo, [:bar, :baz, [:daz]]])

      expect(step.get(:depends_on)).to eq([:foo, :bar, :baz, :daz])
    end

    it 'allows multiple arguments' do
      step.depends_on(:foo, :bar, :baz)

      expect(step.get(:depends_on)).to eq([:foo, :bar, :baz])
    end

    it 'acts as getter when there are no values' do
      step.depends_on(:foo, :bar, :baz)

      expect(step.depends_on).to eq([:foo, :bar, :baz])
    end
  end
end
