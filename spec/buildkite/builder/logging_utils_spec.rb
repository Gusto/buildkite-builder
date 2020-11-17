# frozen_string_literal: true

RSpec.describe Buildkite::Builder::LoggingUtils do
  before do
    klass = Class.new do
      include Buildkite::Builder::LoggingUtils
    end
    stub_const('Dummy', klass)
  end

  let(:dummy) { Dummy.new }

  describe '#benchmark' do
    it 'returns the formatted results string' do
      results = dummy.benchmark('foo %s bar') {}

      expect(results).to match(/foo \d+\.\d+ second(s?) bar/)
    end

    it 'calls the block' do
      block_did_run = false
      dummy.benchmark('foo %s') do
        block_did_run = true
      end

      expect(block_did_run).to eq(true)
    end
  end

  describe '#pluralize' do
    context 'when count is 0' do
      it 'uses the plural string' do
        expect(dummy.pluralize(0, 'foo')).to eq('0 foos')
        expect(dummy.pluralize(0, 'foo', 'bars')).to eq('0 bars')
      end
    end

    context 'when count is 1' do
      it 'uses the singular string' do
        expect(dummy.pluralize(1, 'foo')).to eq('1 foo')
        expect(dummy.pluralize(1, 'foo', 'bars')).to eq('1 foo')
      end
    end

    context 'when count is more than 1' do
      it 'uses the plural string' do
        expect(dummy.pluralize(1.1, 'foo')).to eq('1.1 foos')
        expect(dummy.pluralize(2, 'foo')).to eq('2 foos')
        expect(dummy.pluralize(2, 'foo', 'bars')).to eq('2 bars')
      end
    end
  end
end
