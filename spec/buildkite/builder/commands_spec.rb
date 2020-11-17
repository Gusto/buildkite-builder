# frozen_string_literal: true

RSpec.describe Buildkite::Builder::Commands do
  describe '::COMMANDS' do
    it 'defines all commands' do
      described_class::COMMANDS.each do |_command, command_const|
        expect {
          described_class.const_get(command_const)
        }.not_to raise_error
      end
    end
  end

  describe '.run' do
    let(:argv) { [] }

    before do
      stub_const('ARGV', argv)
    end

    context 'when ARGV is empty' do
      it 'prints help' do
        expect(described_class).to receive(:print_help)

        described_class.run
      end
    end

    context 'when help is requested' do
      let(:argv) { ['--help'] }

      it 'prints help' do
        expect(described_class).to receive(:print_help)

        described_class.run
      end
    end

    context 'when a command is given' do
      context 'when invalid command' do
        let(:argv) { ['invalid'] }

        it 'raises an error' do
          expect {
            described_class.run
          }.to raise_error(RuntimeError, /Invalid command/)
        end
      end

      context 'when valid command' do
        it 'executes the command' do
          described_class::COMMANDS.each do |command, command_const|
            stub_const('ARGV', [command])

            expect(described_class.const_get(command_const)).to receive(:execute)

            described_class.run
          end
        end
      end
    end
  end

  describe '.print_help' do
    it 'prints to stdout' do
      expect {
        described_class.print_help
      }.to output(/--help/).to_stdout
    end
  end
end
