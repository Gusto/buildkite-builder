# frozen_string_literal: true

require 'logger'

RSpec.describe Buildkite::Builder::Processors::Abstract do
  let(:runner) do
    instance_double(Buildkite::Builder::Runner, log: Logger.new)
  end

  describe '.process' do
    let(:foo_processor) do
      Class.new(Buildkite::Builder::Processors::Abstract) do
        def self.name
          'FooProcessor'
        end

        def process
        end
      end
    end

    let(:abstract_processor) { described_class }

    it 'raises an error' do
      expect { abstract_processor.process(runner) }.to raise_error(NotImplementedError)
    end

    context 'with an implemented processor' do
      it 'processes' do
        expect(foo_processor.process(runner)).to be_truthy
      end
    end
  end
end
