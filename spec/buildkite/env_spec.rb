# frozen_string_literal: true

RSpec.describe Buildkite::Env do
  let(:env) do
    { 'BUILDKITE' => 'true' }
  end

  describe '.load' do
    context 'when in Buildkite environment' do
      it 'returns Env' do
        instance = described_class.load(env)
        expect(instance).to be_a(described_class)
      end
    end

    context 'when not in Buildkite environment' do
      it 'returns nil' do
        expect(described_class.load({})).to be_nil
      end
    end
  end

  describe '#default_branch?' do
    it 'returns true when matched' do
      instance = described_class.load(env.merge(
        'BUILDKITE_BRANCH' => 'development',
        'BUILDKITE_PIPELINE_DEFAULT_BRANCH' => 'development'
      ))

      expect(instance).to be_default_branch
    end

    it 'returns false when not matched' do
      instance = described_class.load(env.merge(
        'BUILDKITE_BRANCH' => 'feature',
        'BUILDKITE_PIPELINE_DEFAULT_BRANCH' => 'development'
      ))

      expect(instance).not_to be_default_branch
    end
  end

  describe '#pull_request' do
    it 'returns false when not pull request' do
      instance = described_class.load(env.merge(
        'BUILDKITE_PULL_REQUEST' => 'false'
      ))

      expect(instance.pull_request).to eq(false)
    end

    it 'returns the pull request number' do
      instance = described_class.load(env.merge(
        'BUILDKITE_PULL_REQUEST' => '123'
      ))

      expect(instance.pull_request).to eq(123)
    end
  end

  describe '#build_number' do
    it 'returns the build number' do
      instance = described_class.load(env.merge(
        'BUILDKITE_BUILD_NUMBER' => '123'
      ))

      expect(instance.build_number).to eq(123)
    end
  end

  describe '#method_missing' do
    it 'returns the environment value' do
      instance = described_class.load(env.merge(
        'BUILDKITE_WHATEVER' => 'foo'
      ))

      expect(instance.whatever).to eq('foo')
    end

    it 'returns whether or not environment variable exists' do
      instance = described_class.load(env.merge(
        'BUILDKITE_WHATEVER' => 'foo'
      ))

      expect(instance.whatever?).to eq(true)
      expect(instance.whatever_foo?).to eq(false)
    end

    it 'raises an error when environment variable does not exist' do
      instance = described_class.load(env)

      expect {
        instance.bad_variable
      }.to raise_error(NoMethodError, /BUILDKITE_BAD_VARIABLE/)
    end
  end
end
