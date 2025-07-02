# frozen_string_literal: true

RSpec.describe Buildkite::Pipelines::Helpers::Matrix do
  let(:step_klass) do
    Class.new do
      include Buildkite::Pipelines::Attributes

      attribute :matrix
    end
  end

  let(:step) { step_klass.new }

  describe '#matrix' do
    context 'when called without arguments' do
      it 'returns the matrix value' do
        step.set(:matrix, ['linux', 'macos'])
        expect(step.matrix).to eq(['linux', 'macos'])
      end

      it 'returns nil when matrix is not set' do
        expect(step.matrix).to be_nil
      end
    end

    context 'when called with a value argument' do
      it 'sets the matrix to an array value' do
        step.matrix(['ubuntu', 'windows'])
        expect(step.get(:matrix)).to eq(['ubuntu', 'windows'])
      end

      it 'sets the matrix to a string value' do
        step.matrix('linux')
        expect(step.get(:matrix)).to eq('linux')
      end

      it 'sets the matrix to any value type' do
        step.matrix({ os: 'linux' })
        expect(step.get(:matrix)).to eq({ os: 'linux' })
      end
    end

    context 'when called with setup keyword argument' do
      it 'sets the matrix with setup configuration' do
        setup_config = {
          os: ['linux', 'macos', 'windows'],
          arch: ['amd64', 'arm64']
        }
        step.matrix(setup: setup_config)
        expect(step.get(:matrix)).to eq({ setup: setup_config })
      end

      it 'sets the matrix with empty setup' do
        step.matrix(setup: {})
        expect(step.get(:matrix)).to eq({ setup: {} })
      end

      it 'accepts any type for setup' do
        step.matrix(setup: ['linux'])
        expect(step.get(:matrix)).to eq({ setup: ['linux'] })
      end
    end

    context 'when both value and setup are provided' do
      it 'prioritizes setup over value' do
        setup_config = { os: ['linux'] }
        step.matrix('ignored_value', setup: setup_config)
        expect(step.get(:matrix)).to eq({ setup: setup_config })
      end
    end
  end
end
