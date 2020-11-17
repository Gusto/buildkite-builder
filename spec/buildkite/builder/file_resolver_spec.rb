# frozen_string_literal: true

RSpec.describe Buildkite::Builder::FileResolver do
  describe '.resolve' do
    context 'when PR' do
      let(:files) do
        [
          { 'filename' => 'file_1' },
          { 'filename' => 'file_2' },
        ]
      end

      before do
        stub_buildkite_env(pull_request: '12345')
        allow(Buildkite::Builder::Github).to receive(:pull_request_files).and_return(files)
      end

      it 'returns the resolver' do
        resolver = described_class.resolve

        expect(resolver).to be_a(described_class)
        expect(resolver.modified_files).to eq(Set.new(['file_1', 'file_2']))
      end
    end

    context 'when not PR' do
      context 'when CI' do
        before { stub_buildkite_env(pull_request: false, commit: 'a1b2c3') }

        it 'sends command' do
          expect(Open3).to receive(:capture2).with('git', 'diff-tree', '--no-commit-id', '--name-only', '-r', 'a1b2c3').and_return([spy, spy(success?: true)]) # rubocop:disable RSpec/VerifiedDoubles

          described_class.resolve
        end
      end

      context 'when not CI' do
        it 'sends command' do
          # Get branch
          expect(Open3).to receive(:capture2).with('git', 'symbolic-ref', 'refs/remotes/origin/HEAD').and_return(['foo', spy(success?: true)]).ordered # rubocop:disable RSpec/VerifiedDoubles
          # Pass branch in
          expect(Open3).to receive(:capture2).with('git', 'diff', '--name-only', 'foo').and_return([spy, spy(success?: true)]).ordered # rubocop:disable RSpec/VerifiedDoubles
          # Last diff
          expect(Open3).to receive(:capture2).with('git', 'diff', '--name-only').and_return([spy, spy(success?: true)]).ordered # rubocop:disable RSpec/VerifiedDoubles

          described_class.resolve
        end
      end
    end
  end
end
