# frozen_string_literal: true

require 'optparse'

RSpec.describe Buildkite::Builder::Commands::Abstract do
  let(:fake_command) do
    stub_const(
      'Buildkite::Builder::Commands::Fake',
      (Class.new(described_class) do
        self.description = 'fake description'

        attr_accessor :parse_options_opts
        def parse_options(opts)
          self.parse_options_opts = opts

          opts.on('--fake') do
            options[:fake] = 'fake'
          end
        end

        attr_accessor :run_options
        def run
          self.run_options = options
        end
      end)
    )
  end

  describe '.description' do
    it 'returns the description set by the subclass' do
      expect(fake_command.description).to eq('fake description')
    end
  end

  describe '.execute' do
    it 'instantiates a new command a calls execute' do
      fake = double
      expect(fake_command).to receive(:new).and_return(fake)
      expect(fake).to receive(:execute)

      fake_command.execute
    end
  end

  describe '.new' do
    let(:argv) { [] }

    before do
      stub_const('ARGV', argv)
    end

    it 'allows the command to parse options' do
      fake = fake_command.new

      expect(fake.parse_options_opts).to be_a(OptionParser)
    end
  end

  describe '#execute' do
    let(:argv) { [] }

    before do
      stub_const('ARGV', argv)
    end

    context 'when help menu is requested' do
      let(:argv) { ['--help'] }

      it 'handles the help option' do
        fake = fake_command.new
        expect(fake).to receive(:puts)

        fake.execute
      end
    end

    context 'when running with options' do
      let(:argv) { ['--fake'] }

      it 'calls the run with options' do
        fake = fake_command.new
        fake.execute

        expect(fake.run_options).to eq(fake: 'fake')
      end
    end
  end
end
